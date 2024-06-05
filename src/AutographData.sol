// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollection.sol";

contract AutographData {
    AutographAccessControl public autographAccessControl;
    AutographCollection public autographCollection;
    AutographLibrary.Autograph private _autograph;
    string public symbol;
    string public name;
    uint256 private _collectionCounter;
    uint256 private _vig;
    uint256 private _hoodieBase;
    uint256 private _shirtBase;
    uint16 private _galleryCounter;

    error InvalidAddress();

    event AutographCreated(string uri, uint256 amount);
    event GalleryCreated(
        uint256[] collectionIds,
        address designer,
        uint16 galleryId
    );
    event GalleryUpdated(
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
    event PublicationConnected(
        uint256 pubId,
        uint256 profileId,
        uint256 collectionId,
        uint16 galleryId
    );

    modifier OnlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
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

    modifier OnlyOpenActionOrCollection() {
        if (
            !autographAccessControl.isOpenAction(msg.sender) &&
            msg.sender != address(autographCollection)
        ) {
            revert InvalidAddress();
        }
        _;
    }

    mapping(uint16 => mapping(uint256 => AutographLibrary.Collection))
        private _collections;
    mapping(uint16 => uint256[]) private _galleryCollections;
    mapping(address => uint16[]) private _designerGallery;
    mapping(uint16 => bool) private _galleryEditable;
    mapping(uint256 => mapping(uint256 => uint256))
        private _publicationCollection;
    mapping(uint256 => mapping(uint256 => uint16)) private _publicationGallery;
    mapping(uint16 => uint256) private _collectionCount;
    mapping(uint256 => uint16) private _collectionGallery;

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographCollection
    ) {
        symbol = _symbol;
        name = _name;
        _collectionCounter = 0;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographCollection = AutographCollection(_autographCollection);
    }

    function createAutograph(
        AutographLibrary.AutographInit memory _auto
    ) external OnlyOpenAction {
        _autograph.id = 1;
        _autograph.uri = _auto.uri;
        _autograph.amount = _auto.amount;
        _autograph.price = _auto.price;
        _autograph.acceptedTokens = _auto.acceptedTokens;
        _autograph.designer = _auto.designer;
        _autograph.pubId = _auto.pubId;
        _autograph.profileId = _auto.profileId;

        emit AutographCreated(_auto.uri, _auto.amount);
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
            _collections[_galleryCounter][_collectionCounter].price = _colls
                .prices[i];
            _collections[_galleryCounter][_collectionCounter]
                .acceptedTokens = _colls.acceptedTokens[i];
            _collections[_galleryCounter][_collectionCounter]
                .collectionType = _colls.collectionTypes[i];
            _collections[_galleryCounter][_collectionCounter]
                .designer = _designer;

            _galleryCollections[_galleryCounter].push(_collectionCounter);
            _collectionGallery[_collectionCounter] = _galleryCounter;
        }

        _collectionCount[_galleryCounter] = _colls.amounts.length;

        uint[] memory _collectionCounts = new uint[](_colls.amounts.length);
        for (uint i = _collectionCounter; i > 0; i--) {
            _collectionCounts[i] = _collectionCounter - i;
        }
        emit GalleryCreated(_collectionCounts, _designer, _galleryCounter);
    }

    function addCollections(
        AutographLibrary.CollectionInit memory _colls,
        address _designer,
        uint16 _galleryId
    ) external OnlyCollection {
        for (uint8 i = 0; i < _colls.amounts.length; i++) {
            _collectionCounter++;
            _collections[_galleryId][_collectionCounter].galleryId = _galleryId;
            _collections[_galleryId][_collectionCounter]
                .galleryId = _collectionCounter;
            _collections[_galleryId][_collectionCounter].uri = _colls.uris[i];
            _collections[_galleryId][_collectionCounter].amount = _colls
                .amounts[i];
            _collections[_galleryId][_collectionCounter].price = _colls.prices[
                i
            ];
            _collections[_galleryId][_collectionCounter].acceptedTokens = _colls
                .acceptedTokens[i];
            _collections[_galleryId][_collectionCounter].collectionType = _colls
                .collectionTypes[i];
            _collections[_galleryId][_collectionCounter].designer = _designer;

            _galleryCollections[_galleryId].push(_collectionCounter);
        }

        _collectionCount[_galleryId] =
            _collectionCount[_galleryId] +
            _colls.amounts.length;

        uint[] memory _collectionCounts = new uint[](_colls.amounts.length);
        for (uint i = _collectionCounter; i > 0; i--) {
            _collectionCounts[i] = _collectionCounter - i;
        }
        emit GalleryUpdated(_collectionCounts, _designer, _galleryId);
    }

    function connectPublication(
        uint256 _pubId,
        uint256 _profileId,
        uint256 _collectionId,
        uint16 _galleryId
    ) public OnlyOpenAction {
        _collections[_galleryId][_collectionId].pubIds.push(_pubId);
        _collections[_galleryId][_collectionId].profileIds.push(_profileId);

        _publicationCollection[_profileId][_pubId] = _collectionId;
        _publicationGallery[_profileId][_pubId] = _galleryId;

        emit PublicationConnected(
            _pubId,
            _profileId,
            _collectionId,
            _galleryId
        );
    }

    function deleteGallery(
        address _designer,
        uint16 _galleryId
    ) external OnlyCollection {
        uint16[] storage _galleries = _designerGallery[_designer];

        for (uint16 i = 0; i < _galleries.length; i++) {
            AutographLibrary.Collection memory _coll = _collections[_galleryId][
                _galleries[i]
            ];

            uint256[] memory _profs = _coll.profileIds;

            for (uint16 j = 0; j < _profs.length; j++) {
                delete _publicationCollection[_profs[j]][_coll.pubIds[j]];
                delete _publicationGallery[_profs[j]][_coll.pubIds[j]];
            }

            delete _coll;
        }

        for (uint16 i = 0; i < _galleries.length; i++) {
            if (_galleries[i] == _galleryId) {
                _galleries[i] = _galleries[_galleries.length - 1];
                _galleries.pop();
                break;
            }
        }

        delete _collectionCount[_galleryId];
        delete _galleryEditable[_galleryId];
        delete _galleryCollections[_galleryId];

        emit GalleryDeleted(_designer, _galleryId);
    }

    function deleteCollection(
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyCollection {
        uint256[] storage _colls = _galleryCollections[_galleryId];

        for (uint16 i = 0; i < _colls.length; i++) {
            if (_colls[i] == _collectionId) {
                _colls[i] = _colls[_colls.length - 1];
                _colls.pop();
                break;
            }
        }

        uint256[] memory _profs = _collections[_galleryId][_collectionId]
            .profileIds;

        for (uint16 i = 0; i < _profs.length; i++) {
            delete _publicationCollection[_profs[i]][
                _collections[_galleryId][_collectionId].pubIds[i]
            ];
        }

        delete _collectionGallery[_collectionCounter];
        delete _collections[_galleryId][_collectionId];

        _collectionCount[_galleryId] = _collectionCount[_galleryId] - 1;

        emit CollectionDeleted(_collectionId, _galleryId);
    }

    function setMintedTokens(
        uint256 _tokenId,
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyCollection {
        _collections[_galleryId][_collectionId].mintedTokenIds.push(_tokenId);

        if (!_galleryEditable[_galleryId]) {
            _galleryEditable[_galleryId] = false;
        }

        emit CollectionTokenMinted(_tokenId, _collectionId, _galleryId);
    }

    function setVig(uint256 _newVig) public OnlyAdmin {
        _vig = _newVig;
    }

    function setHoodieBase(uint256 _newBase) public OnlyAdmin {
        _hoodieBase = _newBase;
    }

    function setShirtBase(uint256 _newBase) public OnlyAdmin {
        _shirtBase = _newBase;
    }

    function getAutographURI() public view returns (string memory) {
        return _autograph.uri;
    }

    function getAutographAmount() public view returns (uint256) {
        return _autograph.amount;
    }

    function getAutographPrice() public view returns (uint256) {
        return _autograph.price;
    }

    function getAutographAcceptedTokens()
        public
        view
        returns (address[] memory)
    {
        return _autograph.acceptedTokens;
    }

    function getAutographProfileId() public view returns (uint256) {
        return _autograph.profileId;
    }

    function getAutographPubId() public view returns (uint256) {
        return _autograph.pubId;
    }

    function getAutographDesigner() public view returns (address) {
        return _autograph.designer;
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

    function getCollectionPriceByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256) {
        return _collections[_galleryId][_collectionId].price;
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

    function getCollectionByPublication(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (uint256) {
        return _publicationCollection[_profileId][_pubId];
    }

    function getGalleryByPublication(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (uint16) {
        return _publicationGallery[_profileId][_pubId];
    }

    function getMintedTokenIdsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].mintedTokenIds;
    }

    function getGalleryCollectionCount(
        uint16 _galleryId
    ) public view returns (uint256) {
        return _collectionCount[_galleryId];
    }

    function getGalleryCollections(
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _galleryCollections[_galleryId];
    }

    function getCollectionGallery(
        uint256 _collectionId
    ) public view returns (uint16) {
        return _collectionGallery[_collectionId];
    }

    function getCollectionCounter() public view returns (uint256) {
        return _collectionCounter;
    }

    function getGalleryCounter() public view returns (uint256) {
        return _galleryCounter;
    }

    function getVig() public view returns (uint256) {
        return _vig;
    }

    function getHoodieBase() public view returns (uint256) {
        return _hoodieBase;
    }

    function getShirtBase() public view returns (uint256) {
        return _shirtBase;
    }
}
