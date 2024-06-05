// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./print/PrintSplitsData.sol";
import "./AutographNFT.sol";
import "./AutographCollection.sol";
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

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographData,
        address _printSplitsData,
        address _autographNFT,
        address _autographCollection
    ) {
        symbol = _symbol;
        name = _name;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographData = AutographData(_autographData);
        printSplitsData = PrintSplitsData(_printSplitsData);
        autographNFT = AutographNFT(_autographNFT);
        autographCollection = AutographCollection(_autographCollection);
    }

    function buyTokens(
        address[] memory _currencies,
        uint256[] memory _collectionIds,
        uint8[] memory _quantities,
        AutographLibrary.AutographType[] memory _types,
        string memory _encryptedFulfillment
    ) external {
        uint256 _total = _checkAndSend(
            _currencies,
            _quantities,
            _collectionIds,
            _types,
            msg.sender
        );

        createOrder(_encryptedFulfillment, _total);
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

        uint256 _total = _checkAndSend(
            _currencies,
            _quantities,
            _collectionIds,
            _types,
            _buyer
        );

        createOrder(_encryptedFulfillment, _total);
    }

    function _checkAndSend(
        address[] memory _currencies,
        uint8[] memory _quantities,
        uint256[] memory _collectionIds,
        AutographLibrary.AutographType[] memory _types,
        address _buyer
    ) internal returns (uint256) {
        uint256 _total = 0;

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            uint16 _galleryId = autographData.getCollectionGallery(
                _collectionIds[i]
            );
            address[] memory acceptedTokens = autographData
                .getCollectionAcceptedTokensByGalleryId(
                    _collectionIds[i],
                    _galleryId
                );

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

            if (
                autographData
                    .getMintedTokenIdsByGalleryId(_collectionIds[i], _galleryId)
                    .length +
                    _quantities[i] >
                autographData.getCollectionAmountByGalleryId(
                    _collectionIds[i],
                    _galleryId
                )
            ) {
                revert ExceedAmount();
            }

            _total += _transferTokens(
                _currencies[i],
                _buyer,
                _collectionIds[i],
                _quantities[i],
                _galleryId,
                _types[i]
            );
        }

        return _total;
    }

    function _transferTokens(
        address _chosenCurrency,
        address _buyer,
        uint256 _collectionId,
        uint8 _chosenAmount,
        uint16 _galleryId,
        AutographLibrary.AutographType _type
    ) internal returns (uint256) {
        uint256 _designerAmount = 0;
        uint256 _fulfillerAmount = 0;
        address _designer = address(0);
        address _fulfiller = address(0);

        if (_type == AutographLibrary.AutographType.Catalog) {
            _designerAmount = autographData.getAutographPrice() * _chosenAmount;
            _designer = autographData.getAutographDesigner();

            autographNFT.mintBatch(_buyer, _chosenAmount);

            createSubOrderCatalog();
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

            if (_type == AutographLibrary.AutographType.CollectionNFT) {} else {
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

            autographCollection.mintCollection(
                _buyer,
                _collectionId,
                _galleryId,
                _chosenAmount
            );

            if (_type == AutographLibrary.AutographType.CollectionNFT) {
                createSubOrderDigital();
            } else {
                createSubOrderPhysical();
            }
        } else if (_type == AutographLibrary.AutographType.Mix) {}

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

        return _designerAmount + _fulfillerAmount;
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

    function createSubOrderCatalog() internal {}

    function createSubOrderPhysical() internal {}

    function createSubOrderDigital() internal {}

    function createOrder(
        string memory _encryptedFulfillment,
        uint256 _total
    ) internal {}
}
