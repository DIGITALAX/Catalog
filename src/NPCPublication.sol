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
    ) public view returns (AutographLibrary.LensType, address, uint8) {
        uint256 minCount1 = type(uint256).max;
        uint256 minCount2 = type(uint256).max;
        AutographLibrary.LensType minLensType1 = AutographLibrary
            .LensType
            .Comment;
        AutographLibrary.LensType minLensType2 = AutographLibrary
            .LensType
            .Comment;

        for (uint8 i = 0; i < 4; i++) {
            AutographLibrary.LensType lensType = AutographLibrary.LensType(i);
            uint256 count = _lensTypeByNPC[_npcWallet][lensType];
            if (count < minCount1) {
                minCount2 = minCount1;
                minLensType2 = minLensType1;
                minCount1 = count;
                minLensType1 = lensType;
            } else if (count < minCount2) {
                minCount2 = count;
                minLensType2 = lensType;
            }
        }

        AutographLibrary.LensType chosenLensType;
        if (block.timestamp % 2 == 0) {
            chosenLensType = minLensType1;
        } else {
            chosenLensType = minLensType2;
        }

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
                if (minLensType1 != AutographLibrary.LensType.Autograph) {
                    return (minLensType1, address(0), 0);
                } else {
                    return (minLensType2, address(0), 0);
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
                count < minCount1 &&
                autographData.getArtistCollectionsAvailable(artists[i]).length >
                0
            ) {
                minCount2 = minCount1;
                minArtist2 = minArtist1;
                minCount1 = count;
                minArtist1 = artists[i];
            } else if (
                count < minCount2 &&
                autographData.getArtistCollectionsAvailable(artists[i]).length >
                0
            ) {
                minCount2 = count;
                minArtist2 = artists[i];
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
