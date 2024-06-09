// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./print/PrintSplitsData.sol";
import "./AutographNFT.sol";
import "./AutographCollection.sol";
import "forge-std/console.sol";
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
            _currencies,
            _collectionIds,
            _maxAmount,
            _quantities,
            _types,
            _encryptedFulfillment,
            msg.sender
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
            _currencies,
            _collectionIds,
            new uint256[](1),
            _quantities,
            _types,
            _encryptedFulfillment,
            _buyer
        );
    }

    function _checkAndSend(
        address[] memory _currencies,
        uint256[] memory _collectionIds,
        uint256[] memory _maxAmount,
        uint8[] memory _quantities,
        AutographLibrary.AutographType[] memory _types,
        string memory _encryptedFulfillment,
        address _buyer
    ) internal {
        uint256 _total = 0;
        uint256[] memory _subTotals = new uint256[](_collectionIds.length);
        uint256[] memory _parentIds = new uint256[](_collectionIds.length);
        uint256[][] memory _nftIds = new uint256[][](_collectionIds.length);

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            if (_types[i] != AutographLibrary.AutographType.Mix) {
                _total += _processNonMixType(
                    AutographLibrary.NonMixParams({
                        currencies: _currencies,
                        collectionIds: _collectionIds,
                        quantities: _quantities,
                        types: _types,
                        subTotals: _subTotals,
                        parentIds: _parentIds,
                        nftIds: _nftIds,
                        buyer: _buyer,
                        index: i
                    })
                );
            } else {
                _total += _processMixType(
                    _currencies,
                    _maxAmount,
                    _subTotals,
                    _parentIds,
                    _nftIds,
                    _buyer,
                    i
                );
            }
        }

        autographData.createOrder(
            _nftIds,
            _currencies,
            _collectionIds,
            _quantities,
            _parentIds,
            _subTotals,
            _types,
            _encryptedFulfillment,
            _buyer,
            _total
        );
    }

    function _processNonMixType(
        AutographLibrary.NonMixParams memory _params
    ) internal returns (uint256) {
        uint16 _galleryId = autographData.getCollectionGallery(
            _params.collectionIds[_params.index]
        );
        address[] memory _acceptedTokens;
        if (
            _params.types[_params.index] ==
            AutographLibrary.AutographType.Catalog
        ) {
            _acceptedTokens = autographData.getAutographAcceptedTokens();
        } else {
            _acceptedTokens = autographData
                .getCollectionAcceptedTokensByGalleryId(
                    _params.collectionIds[_params.index],
                    _galleryId
                );
        }

        _checkAcceptedCurrency(_params.currencies, _acceptedTokens);

        if (
            _params.types[_params.index] ==
            AutographLibrary.AutographType.Catalog
        ) {
            if (
                autographData
                    .getMintedTokenIdsByGalleryId(
                        _params.collectionIds[_params.index],
                        _galleryId
                    )
                    .length +
                    _params.quantities[_params.index] >
                autographData.getAutographAmount()
            ) {
                revert ExceedAmount();
            }
        } else {
            if (
                autographData
                    .getMintedTokenIdsByGalleryId(
                        _params.collectionIds[_params.index],
                        _galleryId
                    )
                    .length +
                    _params.quantities[_params.index] >
                autographData.getCollectionAmountByGalleryId(
                    _params.collectionIds[_params.index],
                    _galleryId
                )
            ) {
                revert ExceedAmount();
            }
        }

        (uint256[] memory _nfts, uint256 _value) = _transferTokens(
            _params.currencies[_params.index],
            _params.buyer,
            _params.collectionIds[_params.index],
            _params.quantities[_params.index],
            _galleryId,
            _params.types[_params.index]
        );


        _params.subTotals[_params.index] = _value;
        _params.parentIds[_params.index] = 0;
        _params.nftIds[_params.index] = _nfts;
        return _value;
    }

    function _checkAcceptedCurrency(
        address[] memory _currencies,
        address[] memory acceptedTokens
    ) internal pure {
        bool _found = false;

        for (uint256 k = 0; k < acceptedTokens.length; k++) {
            for (uint256 l = 0; l < _currencies.length; l++) {
                if (_currencies[l] == acceptedTokens[k]) {
                    _found = true;
                    break;
                }
            }
            if (_found) {
                break;
            }
        }

        if (!_found) {
            revert CurrencyNotWhitelisted();
        }
    }

    // function _checkExceedAmount(
    //     uint256[] memory _collectionIds,
    //     uint8[] memory _quantities,
    //     uint16 _galleryId,
    //     uint256 i
    // ) internal view {
    //     if (
    //         autographData
    //             .getMintedTokenIdsByGalleryId(_collectionIds[i], _galleryId)
    //             .length +
    //             _quantities[i] >
    //         autographData.getCollectionAmountByGalleryId(
    //             _collectionIds[i],
    //             _galleryId
    //         )
    //     ) {
    //         revert ExceedAmount();
    //     }
    // }

    function _processMixType(
        address[] memory _currencies,
        uint256[] memory _maxAmount,
        uint256[] memory _subTotals,
        uint256[] memory _parentIds,
        uint256[][] memory _nftIds,
        address _buyer,
        uint256 i
    ) internal returns (uint256) {
        (
            uint256[] memory _nfts,
            uint256 _parentId,
            uint256 _value
        ) = _createMix(_buyer, _currencies[i], _maxAmount[i]);

        _subTotals[i] = _value;
        _parentIds[i] = _parentId;
        _nftIds[i] = _nfts;
        return _value;
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
        address _chosenCurrency,
        address _buyer,
        uint256 _collectionId,
        uint8 _chosenAmount,
        uint16 _galleryId,
        AutographLibrary.AutographType _type
    ) internal returns (uint256[] memory, uint256) {
        uint256[] memory _nftIds = new uint256[](_chosenAmount);
        uint256 _designerAmount = 0;
        uint256 _fulfillerAmount = 0;
        address _designer = address(0);
        address _fulfiller = address(0);

        if (_type == AutographLibrary.AutographType.Catalog) {
            _designerAmount = autographData.getAutographPrice() * _chosenAmount;
            _designer = autographData.getAutographDesigner();
            _nftIds = autographNFT.mintBatch(_buyer, _chosenAmount);
        } else if (
            _type == AutographLibrary.AutographType.CollectionHoodie ||
            _type == AutographLibrary.AutographType.CollectionShirt ||
            _type == AutographLibrary.AutographType.CollectionNFT
        ) {
            uint256 _base = 0;
            _fulfiller = autographAccessControl.getFulfiller();
            _designer = autographData.getCollectionDesignerByGalleryId(
                _collectionId,
                _galleryId
            );
            _designerAmount =
                autographData.getCollectionPriceByGalleryId(
                    _collectionId,
                    _galleryId
                ) *
                _chosenAmount;

            if (_type != AutographLibrary.AutographType.CollectionNFT) {
                if (_type == AutographLibrary.AutographType.CollectionHoodie) {
                    _base = autographData.getHoodieBase();
                } else {
                    _base = autographData.getShirtBase();
                }

                _fulfillerAmount =
                    _base +
                    _designerAmount *
                    autographData.getVig();

                _designerAmount = _designerAmount - _fulfillerAmount;
            }

            _nftIds = autographCollection.mintCollection(
                _buyer,
                _collectionId,
                _galleryId,
                _chosenAmount
            );
        }

        if (_fulfiller != address(0) && _fulfillerAmount > 0) {
            _fulfillerAmount = _calculateAmount(
                _chosenCurrency,
                _fulfillerAmount
            );
            IERC20(_chosenCurrency).transferFrom(
                _buyer,
                _designer,
                _fulfillerAmount
            );
        }

        if (_designer != address(0) && _designerAmount > 0) {
            _designerAmount = _calculateAmount(
                _chosenCurrency,
                _designerAmount
            );
            IERC20(_chosenCurrency).transferFrom(
                _buyer,
                _designer,
                _designerAmount
            );
        }

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
    ) internal returns (uint256[] memory, uint256, uint256) {
        (
            uint256[] memory _selectedCollectionIds,
            uint16[] memory _galleries
        ) = _selectRandomNFTs(_currency, _maxAmount);
        uint256 _total = 0;
        for (uint256 i = 0; i < _selectedCollectionIds.length; i++) {
            uint256 _sub = _calculateAmount(
                _currency,
                autographData.getCollectionPriceByGalleryId(
                    _selectedCollectionIds[i],
                    _galleries[i]
                )
            );

            IERC20(_currency).transferFrom(
                _buyer,
                autographData.getCollectionDesignerByGalleryId(
                    _selectedCollectionIds[i],
                    _galleries[i]
                ),
                _sub
            );

            _total += _sub;
        }

        (uint256[] memory _childIds, uint256 _parentId) = autographCollection
            .mintMix(_selectedCollectionIds, _galleries, _buyer);

        return (_childIds, _parentId, _total);
    }

    function _selectRandomNFTs(
        address _currency,
        uint256 _maxAmount
    ) internal view returns (uint256[] memory, uint16[] memory) {
        uint256[] memory _availableCollectionIds = autographData.getNFTMix();
        uint256 _numNFTs = 3 +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % 3);
        uint256[] memory _selectedCollectionIds = new uint256[](_numNFTs);
        uint16[] memory _galleries = new uint16[](_numNFTs);
        uint256 _count = 0;
        uint256 _total = 0;

        while (_count < _numNFTs) {
            uint256 index = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, _count)
                )
            ) % _availableCollectionIds.length;
            uint256 _selectedCollectionId = _availableCollectionIds[index];

            if (
                _isAlreadySelected(
                    _selectedCollectionIds,
                    _selectedCollectionId,
                    _count
                )
            ) {
                continue;
            }

            uint16 _galleryId = autographData.getCollectionGallery(
                _selectedCollectionId
            );
            uint256 _price = autographData.getCollectionPriceByGalleryId(
                _selectedCollectionId,
                _galleryId
            );

            if (
                autographData.getAutographCurrencyIsAccepted(
                    _currency,
                    _selectedCollectionId
                ) && _total + _price <= _maxAmount
            ) {
                _selectedCollectionIds[_count] = _selectedCollectionId;
                _galleries[_count] = _galleryId;
                _count++;
            }
        }

        return (_selectedCollectionIds, _galleries);
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
