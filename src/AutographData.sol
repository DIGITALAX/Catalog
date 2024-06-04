// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollection.sol";
import "./AutographMarket.sol";

contract AutographData {
    AutographAccessControl public autographAccessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    string public symbol;
    string public name;
    uint256 private _autographCounter;
    uint16 private _galleryCounter;
    uint256 private _collectionCounter;

    error InvalidAddress();

    event AutographCreated(uint256 autographId, string uri, uint256 amount);
    event GalleryCreated(
        uint256[] collectionIds,
        address designer,
        uint16 galleryId
    );
    event GalleryDeleted(address designer, uint16 galleryId);
    event CollectionDeleted(uint256 collectionId, uint16 galleryId);
    event CollectionTokenMinted(
        uint256 tokenId,
        uint256 collectionId,
        uint16 galleryId
    );

    modifier OnlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyCollection() {
        if (msg.sender != address(autographCollection)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyMarket() {
        if (msg.sender != address(autographMarket)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyOpenActionOrCollection() {
        if (
            !autographAccessControl.isOpenAction(msg.sender) &&
            msg.sender != address(autographCollection)
        ) {
            revert InvalidAddress();
        }
        _;
    }

    mapping(uint256 => AutographLibrary.Autograph) private _autographs;
    mapping(uint16 => mapping(uint256 => AutographLibrary.Collection))
        private _collections;
    mapping(address => uint16[]) private _designerGallery;
    mapping(uint16 => bool) private _galleryEditable;

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographCollection,
        address _autographMarket
    ) {
        symbol = _symbol;
        name = _name;
        _autographCounter = 0;
        _collectionCounter = 0;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographCollection = AutographCollection(_autographCollection);
        autographMarket = AutographMarket(_autographMarket);
    }

    function createAutograph(
        AutographLibrary.AutographInit memory _autograph
    ) external OnlyOpenAction {
        _autographCounter++;

        _autographs[_autographCounter].id = _autographCounter;
        _autographs[_autographCounter].uri = _autograph.uri;
        _autographs[_autographCounter].amount = _autograph.amount;
        _autographs[_autographCounter].prices = _autograph.prices;
        _autographs[_autographCounter].acceptedTokens = _autograph
            .acceptedTokens;
        _autographs[_autographCounter].pubId = _autograph.pubId;
        _autographs[_autographCounter].profileId = _autograph.profileId;

        emit AutographCreated(
            _autographCounter,
            _autograph.uri,
            _autograph.amount
        );
    }

    function createGallery(
        AutographLibrary.CollectionInit memory _colls,
        address _designer
    ) external OnlyOpenActionOrCollection {
        _galleryCounter++;
        _designerGallery[_designer].push(_galleryCounter);
        _galleryEditable[_galleryCounter] = true;
        for (uint8 i = 0; i < _colls.amounts.length; i++) {
            _collectionCounter++;
            _collections[_galleryCounter][_collectionCounter]
                .galleryId = _galleryCounter;
            _collections[_galleryCounter][_collectionCounter]
                .galleryId = _collectionCounter;
            _collections[_galleryCounter][_collectionCounter].uri = _colls.uris[
                i
            ];
            _collections[_galleryCounter][_collectionCounter].amount = _colls
                .amounts[i];
            _collections[_galleryCounter][_collectionCounter].prices = _colls
                .prices[i];
            _collections[_galleryCounter][_collectionCounter]
                .acceptedTokens = _colls.acceptedTokens[i];
            _collections[_galleryCounter][_collectionCounter]
                .collectionType = _colls.collectionTypes[i];
            _collections[_galleryCounter][_collectionCounter]
                .designer = _designer;
        }

        uint[] memory _collectionCounts = new uint[](6);
        for (uint i = 0; i < _collectionCounts.length; i++) {
            _collectionCounts[i] = _collectionCounter + i;
        }
        emit GalleryCreated(_collectionCounts, _designer, _galleryCounter);
    }

    function connectPublication(
        uint256 _pubId,
        uint256 _profileId,
        uint256 _collectionId,
        uint16 _galleryId
    ) public OnlyOpenAction {
        _collections[_galleryId][_collectionId].pubIds.push(_pubId);
        _collections[_galleryId][_collectionId].profileIds.push(_profileId);
    }

    function deleteGallery(
        address _designer,
        uint16 _galleryId
    ) external OnlyCollection {
        uint16[] storage _galleries = _designerGallery[_designer];
        for (uint256 i = 0; i < _galleries.length; i++) {
            if (_galleries[i] == _galleryId) {
                _galleries[i] = _galleries[_galleries.length - 1];
                _galleries.pop();
                break;
            }
        }

        delete _collections[_galleryId];

        emit GalleryDeleted(_designer, _galleryId);
    }

    function deleteCollection(
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyCollection {
        delete _collections[_galleryId][_collectionId];

        emit CollectionDeleted(_collectionId, _galleryId);
    }

    function setMintedTokens(
        uint256 _tokenId,
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyMarket {
        _collections[_galleryId][_collectionId].push(_tokenId);

        if (!_galleryEditable[_galleryId]) {
            _galleryEditable[_galleryId] = false;
        }

        emit CollectionTokenMinted(_tokenId, _collectionId, _galleryId);
    }

    function getAutographURIById(
        uint256 _autographId
    ) public view returns (string memory) {
        return _autographs[_autographId].uri;
    }

    function getAutographAmountById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].amount;
    }

    function getAutographPricesById(
        uint256 _autographId
    ) public view returns (uint256[] memory) {
        return _autographs[_autographId].prices;
    }

    function getAutographAcceptedTokensById(
        uint256 _autographId
    ) public view returns (address[] memory) {
        return _autographs[_autographId].acceptedTokens;
    }

    function getAutographProfileIdById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].profileId;
    }

    function getAutographPubIdById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].pubId;
    }

    function getDesignerGalleries(
        address _designer
    ) public view returns (uint16[] memory) {
        return _designerGallery[_designer];
    }

    function getGalleryLengthByDesigner(
        address _designer
    ) public view returns (uint256) {
        return _designerGallery[_designer].length;
    }

    function getGalleryEditable(uint16 _galleryId) public view returns (bool) {
        return _galleryEditable[_galleryId];
    }

    function getCollectionDesignerByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (address) {
        return _collections[_galleryId][_collectionId].designer;
    }

    function getCollectionURIByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (string memory) {
        return _collections[_galleryId][_collectionId].uri;
    }

    function getCollectionAmountByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256) {
        return _collections[_galleryId][_collectionId].amount;
    }

    function getCollectionPricesByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].prices;
    }

    function getCollectionAcceptedTokensByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (address[] memory) {
        return _collections[_galleryId][_collectionId].acceptedTokens;
    }

    function getCollectionProfileIdsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].profileIds;
    }

    function getCollectionPubIdsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].pubIds;
    }

    function getCollectionTypeByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (AutographLibrary.CollectionType) {
        return _collections[_galleryId][_collectionId].collectionType;
    }

    function getMintedTokenIdsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].mintedTokenIds;
    }

    function getAutographCounter() public view returns (uint256) {
        return _autographCounter;
    }

    function getCollectionCounter() public view returns (uint256) {
        return _collectionCounter;
    }

    function getGalleryCounter() public view returns (uint256) {
        return _galleryCounter;
    }
}
