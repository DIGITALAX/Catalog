// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollection.sol";

contract NPCPublication {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    string public symbol;
    string public name;
    uint256 private _callCount;

    error AddressInvalid();

    event PublicationRegistered(
        address npc,
        uint256 profileId,
        uint256 pubId,
        AutographLibrary.LensType lensType
    );

    mapping(uint256 => mapping(uint256 => AutographLibrary.Publication))
        private _publications;
    mapping(address => mapping(AutographLibrary.LensType => uint256))
        private _lensTypeByNPC;
    mapping(address => mapping(address => uint256)) private _artistByNPC;
    mapping(address => mapping(uint8 => uint256)) private _pageByNPC;

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographData
    ) {
        symbol = _symbol;
        name = _name;
        _callCount = 0;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographData = AutographData(_autographData);
    }

    modifier NPCOnly() {
        if (!autographAccessControl.isNPC(msg.sender)) {
            revert AddressInvalid();
        }
        _;
    }

    function registerPublication(
        address _artist,
        uint256 _profileId,
        uint256 _pubId,
        uint8 _pageNumber,
        AutographLibrary.LensType _lensType
    ) public NPCOnly {
        _publications[_profileId][_pubId].lensType = _lensType;
        _publications[_profileId][_pubId].artist = _artist;
        _publications[_profileId][_pubId].npc = msg.sender;
        _lensTypeByNPC[msg.sender][_lensType] += 1;

        if (_lensType == AutographLibrary.LensType.Catalog) {
            _pageByNPC[msg.sender][_pageNumber] += 1;
        } else if (_lensType == AutographLibrary.LensType.Autograph) {
            _artistByNPC[msg.sender][_artist] += 1;
        }

        emit PublicationRegistered(msg.sender, _profileId, _pubId, _lensType);
    }

    function getPublicationType(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (AutographLibrary.LensType) {
        return _publications[_profileId][_pubId].lensType;
    }

    function getPublicationArtist(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (address) {
        return _publications[_profileId][_pubId].artist;
    }

    function getPublicationNPC(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (address) {
        return _publications[_profileId][_pubId].npc;
    }

    function getPublicationPredictByNPC(
        address _npcWallet
    ) public returns (AutographLibrary.LensType, address, uint8) {
        uint256 _minCount1 = type(uint256).max;
        uint256 _minCount2 = type(uint256).max;
        AutographLibrary.LensType _minLensType1 = AutographLibrary
            .LensType
            .Comment;
        AutographLibrary.LensType _minLensType2 = AutographLibrary
            .LensType
            .Comment;

        AutographLibrary.LensType[4] memory _lensTypes = [
            AutographLibrary.LensType.Catalog,
            AutographLibrary.LensType.Comment,
            AutographLibrary.LensType.Publication,
            AutographLibrary.LensType.Autograph
        ];

        for (uint8 i = 0; i < 4; i++) {
            uint8 n = uint8(
                uint256(keccak256(abi.encodePacked(block.timestamp, i))) % 4
            );
            AutographLibrary.LensType temp = _lensTypes[i];
            _lensTypes[i] = _lensTypes[n];
            _lensTypes[n] = temp;
        }

        for (uint8 i = 0; i < 4; i++) {
            AutographLibrary.LensType _lensType = _lensTypes[i];
            uint256 _count = _lensTypeByNPC[_npcWallet][_lensType];

            if (_count < _minCount1) {
                _minCount2 = _minCount1;
                _minLensType2 = _minLensType1;
                _minCount1 = _count;
                _minLensType1 = _lensType;
            } else if (_count < _minCount2) {
                _minCount2 = _count;
                _minLensType2 = _lensType;
            }
        }

        AutographLibrary.LensType chosenLensType;
        if (_callCount % 2 == 0) {
            chosenLensType = _minLensType1;
        } else {
            chosenLensType = _minLensType2;
        }
        _callCount++;
        if (
            chosenLensType == AutographLibrary.LensType.Comment ||
            chosenLensType == AutographLibrary.LensType.Publication
        ) {
            return (chosenLensType, address(0), 0);
        } else if (chosenLensType == AutographLibrary.LensType.Catalog) {
            uint8 _pageNumber = _findLeastPublishedPage(_npcWallet);
            return (chosenLensType, address(0), _pageNumber);
        } else if (chosenLensType == AutographLibrary.LensType.Autograph) {
            address _selectedArtist = _findLeastPublishedArtistWithAvailableCollections(
                    _npcWallet
                );
            if (_selectedArtist != address(0)) {
                return (chosenLensType, _selectedArtist, 0);
            } else {
                if (_minLensType1 != AutographLibrary.LensType.Autograph) {
                    return (_minLensType1, address(0), 0);
                } else {
                    return (_minLensType2, address(0), 0);
                }
            }
        } else {
            return (chosenLensType, address(0), 0);
        }
    }

    function _findLeastPublishedArtistWithAvailableCollections(
        address _npcWallet
    ) internal view returns (address) {
        address[] memory artists = autographData.getAllArtists();
        uint256 minCount1 = type(uint256).max;
        uint256 minCount2 = type(uint256).max;
        address minArtist1 = address(0);
        address minArtist2 = address(0);

        for (uint256 i = 0; i < artists.length; i++) {
            uint256 count = _artistByNPC[_npcWallet][artists[i]];
            if (
                autographData.getArtistCollectionsAvailable(artists[i]).length >
                0
            ) {
                if (count < minCount1) {
                    minCount2 = minCount1;
                    minArtist2 = minArtist1;
                    minCount1 = count;
                    minArtist1 = artists[i];
                } else if (count < minCount2) {
                    minCount2 = count;
                    minArtist2 = artists[i];
                }
            }
        }

        if (minArtist1 != address(0)) {
            return minArtist1;
        } else {
            return minArtist2;
        }
    }

    function _findLeastPublishedPage(
        address _npcWallet
    ) internal view returns (uint8) {
        uint8 _pages = autographData.getAutographPageCount();
        uint256 minCount1 = type(uint256).max;
        uint256 minCount2 = type(uint256).max;
        uint8 minPage1 = 0;
        uint8 minPage2 = 0;

        for (uint8 i = 0; i < _pages; i++) {
            uint256 count = _pageByNPC[_npcWallet][i];
            if (count < minCount1) {
                minCount2 = minCount1;
                minPage2 = minPage1;
                minCount1 = count;
                minPage1 = i;
            } else if (count < minCount2) {
                minCount2 = count;
                minPage2 = i;
            }
        }

        if (block.timestamp % 2 == 0) {
            return minPage1;
        } else {
            return minPage2;
        }
    }
}
