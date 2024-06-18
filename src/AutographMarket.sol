// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./print/PrintSplitsData.sol";
import "./AutographNFT.sol";
import "./AutographCollection.sol";
import "./AutographLibrary.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AutographMarket {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    PrintSplitsData public printSplitsData;
    AutographNFT public autographNFT;
    AutographCollection public autographCollection;
    string public symbol;
    string public name;

    error InvalidAddress();
    error CurrencyNotWhitelisted();
    error ExceedAmount();
    error InvalidAmounts();
    error InvalidType();
    error NoMixFound();

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

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _printSplitsData,
        address _autographNFT
    ) {
        symbol = _symbol;
        name = _name;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        printSplitsData = PrintSplitsData(_printSplitsData);
        autographNFT = AutographNFT(_autographNFT);
    }

    function buyTokens(
        address[] memory _currencies,
        uint256[] memory _collectionIds,
        uint256[] memory _maxAmount,
        uint8[] memory _quantities,
        AutographLibrary.AutographType[] memory _types,
        string memory _encryptedFulfillment
    ) external {
        _checkAndSend(
            AutographLibrary.Send({
                currencies: _currencies,
                collectionIds: _collectionIds,
                maxAmount: _maxAmount,
                quantities: _quantities,
                types: _types,
                encryptedFulfillment: _encryptedFulfillment,
                buyer: msg.sender
            })
        );
    }

    function buyTokenAction(
        string memory _encryptedFulfillment,
        address _buyer,
        address _currency,
        uint256 _collectionId,
        uint8 _quantity,
        AutographLibrary.AutographType _type
    ) external OnlyOpenAction {
        address[] memory _currencies = new address[](1);
        _currencies[0] = _currency;
        uint256[] memory _collectionIds = new uint256[](1);
        _collectionIds[0] = _collectionId;
        uint8[] memory _quantities = new uint8[](1);
        _quantities[0] = _quantity;
        AutographLibrary.AutographType[]
            memory _types = new AutographLibrary.AutographType[](1);
        _types[0] = _type;

        _checkAndSend(
            AutographLibrary.Send({
                currencies: _currencies,
                collectionIds: _collectionIds,
                maxAmount: new uint256[](1),
                quantities: _quantities,
                types: _types,
                encryptedFulfillment: _encryptedFulfillment,
                buyer: _buyer
            })
        );
    }

    function _checkAndSend(AutographLibrary.Send memory _params) internal {
        uint256 _total = 0;
        uint256[] memory _subTotals = new uint256[](
            _params.collectionIds.length
        );
        uint256[] memory _parentIds = new uint256[](
            _params.collectionIds.length
        );
        uint256[][] memory _nftIds = new uint256[][](
            _params.collectionIds.length
        );
        uint256[][] memory _boughtCollections = new uint256[][](
            _params.collectionIds.length
        );

        for (uint256 i = 0; i < _params.collectionIds.length; i++) {
            if (_params.types[i] != AutographLibrary.AutographType.Mix) {
                _total += _processNonMixType(
                    AutographLibrary.NonMixParams({
                        collectionId: _params.collectionIds[i],
                        currency: _params.currencies[i],
                        quantity: _params.quantities[i],
                        autographType: _params.types[i],
                        buyer: _params.buyer,
                        index: i
                    }),
                    _nftIds,
                    _subTotals
                );
                _boughtCollections[i] = new uint256[](1);
                _boughtCollections[i][0] = _params.collectionIds[i];
                _parentIds[i] = 0;
            } else {
                (
                    uint256[] memory _selectedCollections,
                    uint256 _value,
                    uint256 _parentId
                ) = _processMixType(
                        _nftIds,
                        _subTotals,
                        _params.currencies[i],
                        _params.buyer,
                        _params.maxAmount[i],
                        i
                    );
                _total += _value;
                _parentIds[i] = _parentId;
                _boughtCollections[i] = _selectedCollections;
            }
        }

        autographData.createOrder(
            _nftIds,
            _boughtCollections,
            _params.currencies,
            _params.quantities,
            _parentIds,
            _subTotals,
            _params.types,
            _params.encryptedFulfillment,
            _params.buyer,
            _total
        );
    }

    function _processNonMixType(
        AutographLibrary.NonMixParams memory _params,
        uint256[][] memory _nftIds,
        uint256[] memory _subTotals
    ) internal returns (uint256) {
        uint256 _total = 0;
        uint16 _galleryId = autographData.getCollectionGallery(
            _params.collectionId
        );
        address[] memory _acceptedTokens;
        if (_params.autographType == AutographLibrary.AutographType.Catalog) {
            _acceptedTokens = autographData.getAutographAcceptedTokens();
        } else {
            _acceptedTokens = autographData
                .getCollectionAcceptedTokensByGalleryId(
                    _params.collectionId,
                    _galleryId
                );
        }

        _checkAcceptedCurrency(_acceptedTokens, _params.currency);

        if (_params.autographType == AutographLibrary.AutographType.Catalog) {
            if (
                autographData.getAutographMinted() + _params.quantity >
                autographData.getAutographAmount()
            ) {
                revert ExceedAmount();
            }
        } else {
            if (
                autographData
                    .getMintedTokenIdsByGalleryId(
                        _params.collectionId,
                        _galleryId
                    )
                    .length +
                    _params.quantity >
                autographData.getCollectionAmountByGalleryId(
                    _params.collectionId,
                    _galleryId
                )
            ) {
                revert ExceedAmount();
            }
        }

        (uint256[] memory _nfts, uint256 _value) = _transferTokens(
            AutographLibrary.NonMixTransfer({
                chosenCurrency: _params.currency,
                buyer: _params.buyer,
                collectionId: _params.collectionId,
                chosenAmount: _params.quantity,
                galleryId: _galleryId,
                autographType: _params.autographType
            })
        );

        _subTotals[_params.index] = _value;
        _nftIds[_params.index] = _nfts;
        _total += _value;

        return _total;
    }

    function _checkAcceptedCurrency(
        address[] memory acceptedTokens,
        address _currency
    ) internal pure {
        bool _found = false;

        for (uint256 k = 0; k < acceptedTokens.length; k++) {
            if (_currency == acceptedTokens[k]) {
                _found = true;
                break;
            }
            if (_found) {
                break;
            }
        }

        if (!_found) {
            revert CurrencyNotWhitelisted();
        }
    }

    function _processMixType(
        uint256[][] memory _nftIds,
        uint256[] memory _subTotals,
        address _currency,
        address _buyer,
        uint256 _maxAmount,
        uint256 i
    ) internal returns (uint256[] memory, uint256, uint256) {
        (
            uint256[] memory _nfts,
            uint256[] memory _selectedCollections,
            uint256 _parentId,
            uint256 _value
        ) = _createMix(_buyer, _currency, _maxAmount);

        _subTotals[i] = _value;
        _nftIds[i] = _nfts;

        return (_selectedCollections, _value, _parentId);
    }

    function _checkAcceptedTokens(
        address[] memory acceptedTokens,
        address[] memory _currencies
    ) internal pure returns (bool) {
        for (uint256 k = 0; k < acceptedTokens.length; k++) {
            for (uint256 l = 0; l < _currencies.length; l++) {
                if (_currencies[l] == acceptedTokens[k]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _transferTokens(
        AutographLibrary.NonMixTransfer memory _params
    ) internal returns (uint256[] memory, uint256) {
        (
            uint256[] memory _nftIds,
            address _designer,
            address _fulfiller,
            uint256 _designerAmount,
            uint256 _fulfillerAmount
        ) = _transferType(
                AutographLibrary.TransferType({
                    buyer: _params.buyer,
                    collectionId: _params.collectionId,
                    galleryId: _params.galleryId,
                    chosenAmount: _params.chosenAmount,
                    autographType: _params.autographType
                })
            );

        _designerFulfillerTransfer(
            AutographLibrary.Transfer({
                buyer: _params.buyer,
                fulfiller: _fulfiller,
                designer: _designer,
                chosenCurrency: _params.chosenCurrency,
                designerAmount: _designerAmount,
                fulfillerAmount: _fulfillerAmount
            })
        );

        return (_nftIds, _designerAmount + _fulfillerAmount);
    }

    function _calculateAmount(
        address _currency,
        uint256 _amountInWei
    ) internal view returns (uint256) {
        uint256 _exchangeRate = printSplitsData.getRateByCurrency(_currency);

        if (_exchangeRate == 0) {
            revert InvalidAmounts();
        }

        uint256 _weiDivisor = printSplitsData.getWeiByCurrency(_currency);
        uint256 _tokenAmount = (_amountInWei * _weiDivisor) / _exchangeRate;

        return _tokenAmount;
    }

    function _createMix(
        address _buyer,
        address _currency,
        uint256 _maxAmount
    ) internal returns (uint256[] memory, uint256[] memory, uint256, uint256) {
        (
            uint256[] memory _selectedCollectionIds,
            uint16[] memory _galleries
        ) = _selectRandomNFTs(_currency, _maxAmount);

        uint256 _total = _handleCollectionMix(
            _selectedCollectionIds,
            _galleries,
            _buyer,
            _currency
        );

        (uint256[] memory _childIds, uint256 _parentId) = autographCollection
            .mintMix(_selectedCollectionIds, _galleries, _buyer);

        return (_childIds, _selectedCollectionIds, _parentId, _total);
    }

    function _selectRandomNFTs(
        address _currency,
        uint256 _maxAmount
    ) internal view returns (uint256[] memory, uint16[] memory) {
        uint256[] memory _availableCollectionIds = autographData.getNFTMix();
        uint256[] memory _filteredCollectionIds = new uint256[](
            _availableCollectionIds.length
        );
        uint16[] memory _filteredGalleries = new uint16[](
            _availableCollectionIds.length
        );
        uint256 _filteredCount = 0;

        for (uint256 i = 0; i < _availableCollectionIds.length; i++) {
            uint256 _collectionId = _availableCollectionIds[i];
            uint16 _galleryId = autographData.getCollectionGallery(
                _collectionId
            );
            if (
                autographData.getAutographCurrencyIsAccepted(
                    _currency,
                    _collectionId
                )
            ) {
                _filteredCollectionIds[_filteredCount] = _collectionId;
                _filteredGalleries[_filteredCount] = _galleryId;
                _filteredCount++;
            }
        }

        if (_filteredCount < 1) {
            revert NoMixFound();
        }

        return
            _filterMix(
                _filteredCollectionIds,
                _filteredGalleries,
                _filteredCount,
                _maxAmount
            );
    }

    function _filterMix(
        uint256[] memory _filteredCollectionIds,
        uint16[] memory _filteredGalleries,
        uint256 _filteredCount,
        uint256 _maxAmount
    ) internal view returns (uint256[] memory, uint16[] memory) {
        uint256 _count = 0;
        uint256 _total = 0;
        uint256 _numNFTs = 3 +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % 3);
        if (_numNFTs > _filteredCount) {
            _numNFTs = _filteredCount;
        }

        _internalFilter(
            _filteredCollectionIds,
            _filteredGalleries,
            _filteredCount
        );

        uint256[] memory _selectedCollectionIds = new uint256[](_numNFTs);
        uint16[] memory _galleries = new uint16[](_numNFTs);

        for (uint256 i = 0; i < _filteredCount && _count < _numNFTs; i++) {
            uint256 price = autographData.getCollectionPriceByGalleryId(
                _filteredCollectionIds[i],
                _filteredGalleries[i]
            );
            if (_total + price <= _maxAmount) {
                _selectedCollectionIds[_count] = _filteredCollectionIds[i];
                _galleries[_count] = _filteredGalleries[i];
                _total += price;
                _count++;
            }
        }

        if (_count < _numNFTs) {
            revert NoMixFound();
        }

        return (_selectedCollectionIds, _galleries);
    }

    function _internalFilter(
        uint256[] memory _filteredCollectionIds,
        uint16[] memory _filteredGalleries,
        uint256 _filteredCount
    ) internal view {
        for (uint256 i = 0; i < _filteredCount - 1; i++) {
            for (uint256 j = i + 1; j < _filteredCount; j++) {
                uint256 priceI = autographData.getCollectionPriceByGalleryId(
                    _filteredCollectionIds[i],
                    _filteredGalleries[i]
                );
                uint256 priceJ = autographData.getCollectionPriceByGalleryId(
                    _filteredCollectionIds[j],
                    _filteredGalleries[j]
                );
                if (priceI > priceJ) {
                    (_filteredCollectionIds[i], _filteredCollectionIds[j]) = (
                        _filteredCollectionIds[j],
                        _filteredCollectionIds[i]
                    );
                    (_filteredGalleries[i], _filteredGalleries[j]) = (
                        _filteredGalleries[j],
                        _filteredGalleries[i]
                    );
                }
            }
        }
    }

    function _typeSplits(
        AutographLibrary.Split memory _params
    ) internal view returns (address, address, uint256, uint256) {
        address _designer = address(0);
        address _fulfiller = address(0);
        uint256 _designerAmount = 0;
        uint256 _fulfillerAmount = 0;

        if (
            (_params.autographType == AutographLibrary.AutographType.NFT &&
                autographData.getCollectionTypeByGalleryId(
                    _params.collectionId,
                    _params.galleryId
                ) !=
                AutographLibrary.AutographType.NFT) ||
            (_params.autographType == AutographLibrary.AutographType.Hoodie &&
                autographData.getCollectionTypeByGalleryId(
                    _params.collectionId,
                    _params.galleryId
                ) !=
                AutographLibrary.AutographType.Hoodie) ||
            (_params.autographType == AutographLibrary.AutographType.Shirt &&
                autographData.getCollectionTypeByGalleryId(
                    _params.collectionId,
                    _params.galleryId
                ) !=
                AutographLibrary.AutographType.Shirt)
        ) {
            revert InvalidType();
        }

        uint256 _base = 0;
        _fulfiller = autographAccessControl.getFulfiller();
        _designer = autographData.getCollectionDesignerByGalleryId(
            _params.collectionId,
            _params.galleryId
        );
        _designerAmount =
            autographData.getCollectionPriceByGalleryId(
                _params.collectionId,
                _params.galleryId
            ) *
            _params.chosenAmount;

        if (_params.autographType != AutographLibrary.AutographType.NFT) {
            if (
                _params.autographType == AutographLibrary.AutographType.Hoodie
            ) {
                _base = autographData.getHoodieBase();
            } else {
                _base = autographData.getShirtBase();
            }

            _fulfillerAmount = (_base *
                _params.chosenAmount +
                (((_designerAmount - _base * _params.chosenAmount) *
                    autographData.getVig()) / 100));

            _designerAmount = _designerAmount - _fulfillerAmount;
        }

        return (_designer, _fulfiller, _designerAmount, _fulfillerAmount);
    }

    function _designerFulfillerTransfer(
        AutographLibrary.Transfer memory _params
    ) internal {
        if (_params.fulfiller != address(0) && _params.fulfillerAmount > 0) {
            _params.fulfillerAmount = _calculateAmount(
                _params.chosenCurrency,
                _params.fulfillerAmount
            );
            IERC20(_params.chosenCurrency).transferFrom(
                _params.buyer,
                _params.fulfiller,
                _params.fulfillerAmount
            );
        }

        if (_params.designer != address(0) && _params.designerAmount > 0) {
            _params.designerAmount = _calculateAmount(
                _params.chosenCurrency,
                _params.designerAmount
            );
            IERC20(_params.chosenCurrency).transferFrom(
                _params.buyer,
                _params.designer,
                _params.designerAmount
            );
        }
    }

    function _handleCollectionMix(
        uint256[] memory _selectedCollectionIds,
        uint16[] memory _galleries,
        address _buyer,
        address _currency
    ) internal returns (uint256) {
        uint256 _total = 0;

        for (uint256 i = 0; i < _selectedCollectionIds.length; i++) {
            if (_selectedCollectionIds[i] > 0 && _galleries[i] > 0) {
                (
                    address _designer,
                    address _fulfiller,
                    uint256 _designerAmount,
                    uint256 _fulfillerAmount
                ) = _typeSplits(
                        AutographLibrary.Split({
                            collectionId: _selectedCollectionIds[i],
                            galleryId: _galleries[i],
                            chosenAmount: 1,
                            autographType: autographData
                                .getCollectionTypeByGalleryId(
                                    _selectedCollectionIds[i],
                                    _galleries[i]
                                )
                        })
                    );

                _designerFulfillerTransfer(
                    AutographLibrary.Transfer({
                        buyer: _buyer,
                        fulfiller: _fulfiller,
                        designer: _designer,
                        chosenCurrency: _currency,
                        designerAmount: _designerAmount,
                        fulfillerAmount: _fulfillerAmount
                    })
                );

                _total += _designerAmount + _fulfillerAmount;
            }
        }
        return _total;
    }

    function _transferType(
        AutographLibrary.TransferType memory _params
    ) internal returns (uint256[] memory, address, address, uint256, uint256) {
        uint256[] memory _nftIds = new uint256[](_params.chosenAmount);
        address _designer = address(0);
        address _fulfiller = address(0);
        uint256 _designerAmount = 0;
        uint256 _fulfillerAmount = 0;

        if (_params.autographType == AutographLibrary.AutographType.Catalog) {
            _designerAmount =
                autographData.getAutographPrice() *
                _params.chosenAmount;
            _designer = autographData.getAutographDesigner();
            _nftIds = autographNFT.mintBatch(
                _params.buyer,
                _params.chosenAmount
            );
        } else if (
            _params.autographType == AutographLibrary.AutographType.Hoodie ||
            _params.autographType == AutographLibrary.AutographType.Shirt ||
            _params.autographType == AutographLibrary.AutographType.NFT
        ) {
            (
                _designer,
                _fulfiller,
                _designerAmount,
                _fulfillerAmount
            ) = _typeSplits(
                AutographLibrary.Split({
                    collectionId: _params.collectionId,
                    galleryId: _params.galleryId,
                    chosenAmount: _params.chosenAmount,
                    autographType: _params.autographType
                })
            );

            _nftIds = autographCollection.mintCollection(
                _params.buyer,
                _params.collectionId,
                _params.galleryId,
                _params.chosenAmount
            );
        }

        return (
            _nftIds,
            _designer,
            _fulfiller,
            _designerAmount,
            _fulfillerAmount
        );
    }

    function _isAlreadySelected(
        uint256[] memory _selectedCollectionIds,
        uint256 _selectedCollectionId,
        uint256 _count
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _count; i++) {
            if (_selectedCollectionIds[i] == _selectedCollectionId) {
                return true;
            }
        }
        return false;
    }

    function setAutographCollection(
        address _autographCollection
    ) public OnlyAdmin {
        autographCollection = AutographCollection(_autographCollection);
    }

    function setAutographData(address _autographData) public OnlyAdmin {
        autographData = AutographData(_autographData);
    }
}
