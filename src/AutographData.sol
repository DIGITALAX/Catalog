// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollection.sol";

contract AutographData {
    AutographAccessControl public autographAccessControl;
    AutographLibrary.Autograph private _autograph;
    uint256[] private _nftMix;
    string public symbol;
    string public name;
    address public autographMarket;
    address public autographNFT;
    address public autographCollection;
    uint256 private _collectionCounter;
    uint256 private _orderCounter;
    uint256 private _vig;
    uint256 private _hoodieBase;
    uint256 private _shirtBase;
    uint16 private _galleryCounter;

    error InvalidAddress();
    error CollectionNotFound();

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
        uint256[] tokenIds,
        uint256[] collectionIds,
        uint16[] galleryIds
    );
    event PublicationConnected(
        uint256 pubId,
        uint256 profileId,
        uint256 collectionId,
        uint16 galleryId
    );
    event OrderCreated(
        AutographLibrary.AutographType[] subOrderTypes,
        uint256 total,
        uint256 orderId
    );
    event AutographTokensMinted(uint8 amount);

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

    modifier OnlyDesigner(address _designer) {
        if (!autographAccessControl.isDesigner(_designer)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyCollection() {
        if (msg.sender != (autographCollection)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyMarket() {
        if (msg.sender != autographMarket) {
            revert InvalidAddress();
        }
        _;
    }

    modifier OnlyNFT() {
        if (msg.sender != autographNFT) {
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
    mapping(uint256 => mapping(uint256 => uint256))
        private _publicationCollection;
    mapping(uint16 => uint256) private _collectionCount;
    mapping(uint256 => uint16) private _collectionGallery;
    mapping(uint256 => mapping(address => bool)) private _collectionCurrency;
    mapping(address => uint256[]) private _buyerToOrders;
    mapping(uint256 => AutographLibrary.Order) private _orders;
    mapping(address => uint256[]) private _npcToCollection;
    mapping(uint256 => address[]) private _collectionToNPCs;

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographCollection,
        address _autographMarket,
        address _autographNFT
    ) {
        symbol = _symbol;
        name = _name;
        _collectionCounter = 0;
        _orderCounter = 0;
        _galleryCounter = 0;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographCollection = _autographCollection;
        autographMarket = _autographMarket;
        autographNFT = _autographNFT;
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
        _autograph.pages = _auto.pages;
        _autograph.pageCount = _auto.pageCount;

        emit AutographCreated(_auto.uri, _auto.amount);
    }

    function createGallery(
        AutographLibrary.CollectionInit memory _colls,
        address _designer
    ) external OnlyOpenActionOrCollection OnlyDesigner(_designer) {
        _galleryCounter++;
        _designerGallery[_designer].push(_galleryCounter);
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
            _collections[_galleryCounter][_collectionCounter].npcs = _colls
                .npcs[i];
            _collections[_galleryCounter][_collectionCounter].languages = _colls
                .languages[i];

            _galleryCollections[_galleryCounter].push(_collectionCounter);
            _collectionGallery[_collectionCounter] = _galleryCounter;

            if (_colls.amounts[i] > 2) {
                _nftMix.push(_collectionCounter);
            }

            for (uint8 k = 0; k < _colls.acceptedTokens[i].length; k++) {
                _collectionCurrency[_collectionCounter][
                    _colls.acceptedTokens[i][k]
                ] = true;
            }

            for (uint8 k = 0; k < _colls.npcs[i].length; k++) {
                _npcToCollection[_colls.npcs[i][k]].push(_collectionCounter);
                _collectionToNPCs[_collectionCounter].push(_colls.npcs[i][k]);
            }
        }

        _collectionCount[_galleryCounter] = _colls.amounts.length;

        uint[] memory _collectionCounts = new uint[](_colls.amounts.length);
        for (uint i = 0; i < _colls.amounts.length; i++) {
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
            _collections[_galleryId][_collectionCounter].npcs = _colls.npcs[i];
            _collections[_galleryId][_collectionCounter].languages = _colls
                .languages[i];

            _galleryCollections[_galleryId].push(_collectionCounter);

            if (_collections[_galleryCounter][_collectionCounter].amount > 2) {
                _nftMix.push(_collectionCounter);
            }

            for (uint8 k = 0; k < _colls.acceptedTokens[i].length; k++) {
                _collectionCurrency[_collectionCounter][
                    _colls.acceptedTokens[i][k]
                ] = true;
            }

            for (uint8 k = 0; k < _colls.npcs[i].length; k++) {
                _npcToCollection[_colls.npcs[i][k]].push(_collectionCounter);
                _collectionToNPCs[_collectionCounter].push(_colls.npcs[i][k]);
            }

            _collectionGallery[_collectionCounter] = _galleryId;
        }

        _collectionCount[_galleryId] =
            _collectionCount[_galleryId] +
            _colls.amounts.length;

        uint[] memory _collectionCounts = new uint[](_colls.amounts.length);
        for (uint i = 0; i < _colls.amounts.length; i++) {
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
        uint256[] storage _collecciones = _galleryCollections[_galleryId];

        for (uint256 i = 0; i < _collecciones.length; i++) {
            AutographLibrary.Collection memory _coll = _collections[_galleryId][
                _collecciones[i]
            ];

            for (uint16 k = 0; k < _nftMix.length; k++) {
                if (_nftMix[k] == _coll.collectionId) {
                    _nftMix[k] = _nftMix[_nftMix.length - 1];
                    _nftMix.pop();
                    return;
                }
            }

            uint256[] memory _profs = _coll.profileIds;

            for (uint16 j = 0; j < _profs.length; j++) {
                delete _publicationCollection[_profs[j]][_coll.pubIds[j]];
            }

            for (uint8 k = 0; k < _coll.acceptedTokens.length; k++) {
                delete _collectionCurrency[_coll.collectionId][
                    _coll.acceptedTokens[k]
                ];
            }

            for (
                uint8 k = 0;
                k < _collectionToNPCs[_coll.collectionId].length;
                k++
            ) {
                for (
                    uint8 j = 0;
                    j <
                    _npcToCollection[_collectionToNPCs[_coll.collectionId][k]]
                        .length;
                    j++
                ) {
                    if (
                        _npcToCollection[
                            _collectionToNPCs[_coll.collectionId][k]
                        ][j] == _coll.collectionId
                    ) {
                        uint256 lastIndex = _npcToCollection[
                            _collectionToNPCs[_coll.collectionId][k]
                        ].length - 1;
                        _npcToCollection[
                            _collectionToNPCs[_coll.collectionId][k]
                        ][j] = _npcToCollection[
                            _collectionToNPCs[_coll.collectionId][k]
                        ][lastIndex];
                        _npcToCollection[
                            _collectionToNPCs[_coll.collectionId][k]
                        ].pop();
                        return;
                    }
                }
            }

            delete _collectionGallery[_coll.collectionId];

            delete _coll;
        }

        uint16[] storage _galleries = _designerGallery[_designer];

        for (uint16 i = 0; i < _galleries.length; i++) {
            if (_galleries[i] == _galleryId) {
                _galleries[i] = _galleries[_galleries.length - 1];
                _galleries.pop();
                break;
            }
        }

        delete _collectionCount[_galleryId];
        delete _galleryCollections[_galleryId];

        emit GalleryDeleted(_designer, _galleryId);
    }

    function deleteCollection(
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyCollection {
        uint256[] storage _colls = _galleryCollections[_galleryId];

        bool collectionFound = false;
        for (uint16 i = 0; i < _colls.length; i++) {
            if (_colls[i] == _collectionId) {
                _colls[i] = _colls[_colls.length - 1];
                _colls.pop();
                collectionFound = true;
                break;
            }
        }

        if (!collectionFound) {
            revert CollectionNotFound();
        }

        address _designer = getCollectionDesignerByGalleryId(
            _collectionId,
            _galleryId
        );

        uint256[] memory _profs = _collections[_galleryId][_collectionId]
            .profileIds;

        for (uint16 i = 0; i < _profs.length; i++) {
            delete _publicationCollection[_profs[i]][
                _collections[_galleryId][_collectionId].pubIds[i]
            ];
        }

        for (uint8 k = 0; k < _collectionToNPCs[_collectionId].length; k++) {
            for (
                uint8 j = 0;
                j <
                _npcToCollection[_collectionToNPCs[_collectionId][k]].length;
                j++
            ) {
                if (
                    _npcToCollection[_collectionToNPCs[_collectionId][k]][j] ==
                    _collectionId
                ) {
                    uint256 lastIndex = _npcToCollection[
                        _collectionToNPCs[_collectionId][k]
                    ].length - 1;
                    _npcToCollection[_collectionToNPCs[_collectionId][k]][
                        j
                    ] = _npcToCollection[_collectionToNPCs[_collectionId][k]][
                        lastIndex
                    ];
                    _npcToCollection[_collectionToNPCs[_collectionId][k]].pop();
                    return;
                }
            }
        }

        for (
            uint8 k = 0;
            k < _collections[_galleryId][_collectionId].acceptedTokens.length;
            k++
        ) {
            delete _collectionCurrency[_collectionId][
                _collections[_galleryId][_collectionId].acceptedTokens[k]
            ];
        }

        delete _collectionGallery[_collectionId];
        delete _collections[_galleryId][_collectionId];

        if (_collectionCount[_galleryId] > 0) {
            _collectionCount[_galleryId]--;
        }

        for (uint16 i = 0; i < _nftMix.length; i++) {
            if (_nftMix[i] == _collectionId) {
                _nftMix[i] = _nftMix[_nftMix.length - 1];
                _nftMix.pop();
                return;
            }
        }

        emit CollectionDeleted(_collectionId, _galleryId);
    }

    function setMintedCatalog(uint8 _amount) external OnlyNFT {
        _autograph.minted += _amount;

        emit AutographTokensMinted(_amount);
    }

    function setMintedTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _collectionIds,
        uint16[] memory _galleryIds
    ) external OnlyCollection {
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _collections[_galleryIds[i]][_collectionIds[i]].mintedTokenIds.push(
                    _tokenIds[i]
                );

            if (
                _collections[_galleryIds[i]][_collectionIds[i]]
                    .mintedTokenIds
                    .length <=
                _collections[_galleryIds[i]][_collectionIds[i]].amount
            ) {
                if (
                    _collections[_galleryIds[i]][_collectionIds[i]].amount -
                        _collections[_galleryIds[i]][_collectionIds[i]]
                            .mintedTokenIds
                            .length <
                    2
                ) {
                    for (uint16 k = 0; k < _nftMix.length; k++) {
                        if (
                            _nftMix[k] ==
                            _collections[_galleryIds[i]][_collectionIds[i]]
                                .collectionId
                        ) {
                            _nftMix[k] = _nftMix[_nftMix.length - 1];
                            _nftMix.pop();
                            return;
                        }
                    }
                }
            }
        }

        emit CollectionTokenMinted(_tokenIds, _collectionIds, _galleryIds);
    }

    function createOrder(
        uint256[][] memory _mintedTokenIds,
        uint256[][] memory _collectionIds,
        address[] memory _currencies,
        uint8[] memory _amounts,
        uint256[] memory _parentIds,
        uint256[] memory _subTotals,
        AutographLibrary.AutographType[] memory _subOrderTypes,
        string memory _fulfillment,
        address _buyer,
        uint256 _total
    ) external OnlyMarket {
        _orderCounter++;

        _buyerToOrders[_buyer].push(_orderCounter);

        _orders[_orderCounter] = AutographLibrary.Order({
            orderId: _orderCounter,
            subOrderTypes: _subOrderTypes,
            buyer: _buyer,
            fulfillment: _fulfillment,
            total: _total,
            subTotals: _subTotals,
            currencies: _currencies,
            collectionIds: _collectionIds,
            amounts: _amounts,
            parentIds: _parentIds,
            mintedTokenIds: _mintedTokenIds
        });

        emit OrderCreated(_subOrderTypes, _total, _orderCounter);
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

    function getAutographAmount() public view returns (uint16) {
        return _autograph.amount;
    }

    function getAutographPrice() public view returns (uint256) {
        return _autograph.price;
    }

    function getAutographPageCount() public view returns (uint8) {
        return _autograph.pageCount;
    }

    function getAutographPage(
        uint256 _page
    ) public view returns (string memory) {
        return _autograph.pages[_page - 1];
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

    function getAutographMinted() public view returns (uint16) {
        return _autograph.minted;
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
    ) public view returns (uint8) {
        return _collections[_galleryId][_collectionId].amount;
    }

    function getCollectionPriceByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256) {
        return _collections[_galleryId][_collectionId].price;
    }

    function getCollectionLanguagesByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (string[] memory) {
        return _collections[_galleryId][_collectionId].languages;
    }

    function getCollectionNPCsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (address[] memory) {
        return _collections[_galleryId][_collectionId].npcs;
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
    ) public view returns (AutographLibrary.AutographType) {
        return _collections[_galleryId][_collectionId].collectionType;
    }

    function getCollectionByPublication(
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (uint256) {
        return _publicationCollection[_profileId][_pubId];
    }

    function getMintedTokenIdsByGalleryId(
        uint256 _collectionId,
        uint16 _galleryId
    ) public view returns (uint256[] memory) {
        return _collections[_galleryId][_collectionId].mintedTokenIds;
    }

    function getAutographCurrencyIsAccepted(
        address _currency,
        uint256 _collectionId
    ) public view returns (bool) {
        return _collectionCurrency[_collectionId][_currency];
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

    function getDesignerProfileId(
        address _designer
    ) public view returns (uint256) {
        uint16 _gId = _designerGallery[_designer][0];
        uint256 _cId = _galleryCollections[_gId][0];
        if (_collections[_gId][_cId].profileIds.length > 0) {
            return _collections[_gId][_cId].profileIds[0];
        } else {
            return 0;
        }
    }

    function getBuyerOrderIds(
        address _buyer
    ) public view returns (uint256[] memory) {
        return _buyerToOrders[_buyer];
    }

    function getOrderBuyer(uint256 _orderId) public view returns (address) {
        return _orders[_orderId].buyer;
    }

    function getOrderTotal(uint256 _orderId) public view returns (uint256) {
        return _orders[_orderId].total;
    }

    function getOrderFulfillment(
        uint256 _orderId
    ) public view returns (string memory) {
        return _orders[_orderId].fulfillment;
    }

    function getOrderSubTypes(
        uint256 _orderId
    ) public view returns (AutographLibrary.AutographType[] memory) {
        return _orders[_orderId].subOrderTypes;
    }

    function getOrderAmounts(
        uint256 _orderId
    ) public view returns (uint8[] memory) {
        return _orders[_orderId].amounts;
    }

    function getOrderSubTotals(
        uint256 _orderId
    ) public view returns (uint256[] memory) {
        return _orders[_orderId].subTotals;
    }

    function getOrderParentIds(
        uint256 _orderId
    ) public view returns (uint256[] memory) {
        return _orders[_orderId].parentIds;
    }

    function getOrderCollectionIds(
        uint256 _orderId
    ) public view returns (uint256[][] memory) {
        return _orders[_orderId].collectionIds;
    }

    function getOrderCurrencies(
        uint256 _orderId
    ) public view returns (address[] memory) {
        return _orders[_orderId].currencies;
    }

    function getOrderMintedTokens(
        uint256 _orderId
    ) public view returns (uint256[][] memory) {
        return _orders[_orderId].mintedTokenIds;
    }

    function getNPCToCollections(
        address _npcWallet
    ) public view returns (uint256[] memory) {
        return _npcToCollection[_npcWallet];
    }

    function getCollectionToNPCs(
        uint256 _collectionId
    ) public view returns (address[] memory) {
        return _collectionToNPCs[_collectionId];
    }

    function getNFTMix() public view returns (uint256[] memory) {
        return _nftMix;
    }

    function getCollectionCounter() public view returns (uint256) {
        return _collectionCounter;
    }

    function getOrderCounter() public view returns (uint256) {
        return _orderCounter;
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
