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
        uint256[][] memory _collectionIds,
        address[] memory _currencies,
        uint256[] memory _maxAmount,
        uint8[] memory _quantities,
        AutographLibrary.AutographType[] memory _types,
        string memory _encryptedFulfillment
    ) external {
        _checkAndSend(
            _collectionIds,
            _currencies,
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
        uint256[][] memory _collectionIds = new uint256[][](1);
        _collectionIds[0] = new uint256[](1);
        _collectionIds[0][0] = _collectionId;
        uint8[] memory _quantities = new uint8[](1);
        _quantities[0] = _quantity;
        AutographLibrary.AutographType[]
            memory _types = new AutographLibrary.AutographType[](1);
        _types[0] = _type;

        _checkAndSend(
            _collectionIds,
            _currencies,
            new uint256[](1),
            _quantities,
            _types,
            _encryptedFulfillment,
            _buyer
        );
    }

    function _checkAndSend(
        uint256[][] memory _collectionIds,
        address[] memory _currencies,
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
                        collectionIds: _collectionIds[i],
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
                (
                    uint256[] memory _selectedCollections,
                    uint256 _value
                ) = _processMixType(
                        _currencies,
                        _maxAmount,
                        _subTotals,
                        _parentIds,
                        _nftIds,
                        _buyer,
                        i
                    );

                _total += _value;

                _collectionIds[i] = _selectedCollections;
            }
        }

        autographData.createOrder(
            _nftIds,
            _collectionIds,
            _currencies,
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
        uint256 _total = 0;
        for (uint8 j = 0; j < _params.collectionIds.length; j++) {
            uint16 _galleryId = autographData.getCollectionGallery(
                _params.collectionIds[j]
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
                        _params.collectionIds[j],
                        _galleryId
                    );
            }

            _checkAcceptedCurrency(_params.currencies, _acceptedTokens);

            if (
                _params.types[_params.index] ==
                AutographLibrary.AutographType.Catalog
            ) {
                if (
                    autographData.getAutographMinted() +
                        _params.quantities[_params.index] >
                    autographData.getAutographAmount()
                ) {
                    revert ExceedAmount();
                }
            } else {
                if (
                    autographData
                        .getMintedTokenIdsByGalleryId(
                            _params.collectionIds[j],
                            _galleryId
                        )
                        .length +
                        _params.quantities[_params.index] >
                    autographData.getCollectionAmountByGalleryId(
                        _params.collectionIds[j],
                        _galleryId
                    )
                ) {
                    revert ExceedAmount();
                }
            }

            (uint256[] memory _nfts, uint256 _value) = _transferTokens(
                _params.currencies[_params.index],
                _params.buyer,
                _params.collectionIds[j],
                _params.quantities[_params.index],
                _galleryId,
                _params.types[_params.index]
            );

            _params.subTotals[_params.index] = _value;
            _params.parentIds[_params.index] = 0;
            _params.nftIds[_params.index] = _nfts;

            _total += _value;
        }

        return _total;
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

    function _processMixType(
        address[] memory _currencies,
        uint256[] memory _maxAmount,
        uint256[] memory _subTotals,
        uint256[] memory _parentIds,
        uint256[][] memory _nftIds,
        address _buyer,
        uint256 i
    ) internal returns (uint256[] memory, uint256) {
        (
            uint256[] memory _nfts,
            uint256[] memory _selectedCollections,
            uint256 _parentId,
            uint256 _value
        ) = _createMix(_buyer, _currencies[i], _maxAmount[i]);

        _subTotals[i] = _value;
        _parentIds[i] = _parentId;
        _nftIds[i] = _nfts;
        return (_selectedCollections, _value);
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
            _type == AutographLibrary.AutographType.Hoodie ||
            _type == AutographLibrary.AutographType.Shirt ||
            _type == AutographLibrary.AutographType.NFT
        ) {
            if (
                (_type == AutographLibrary.AutographType.NFT &&
                    autographData.getCollectionTypeByGalleryId(
                        _collectionId,
                        _galleryId
                    ) !=
                    AutographLibrary.AutographType.NFT) ||
                (_type == AutographLibrary.AutographType.Hoodie &&
                    autographData.getCollectionTypeByGalleryId(
                        _collectionId,
                        _galleryId
                    ) !=
                    AutographLibrary.AutographType.Hoodie) ||
                (_type == AutographLibrary.AutographType.Shirt &&
                    autographData.getCollectionTypeByGalleryId(
                        _collectionId,
                        _galleryId
                    ) !=
                    AutographLibrary.AutographType.Shirt)
            ) {
                revert InvalidType();
            }

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

            if (_type != AutographLibrary.AutographType.NFT) {
                if (_type == AutographLibrary.AutographType.Hoodie) {
                    _base = autographData.getHoodieBase();
                } else {
                    _base = autographData.getShirtBase();
                }

                _fulfillerAmount =
                    _base *
                    _chosenAmount +
                    (_designerAmount * autographData.getVig()) /
                    100;

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
                _fulfiller,
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
    ) internal returns (uint256[] memory, uint256[] memory, uint256, uint256) {
        (
            uint256[] memory _selectedCollectionIds,
            uint16[] memory _galleries
        ) = _selectRandomNFTs(_currency, _maxAmount);
        uint256 _total = 0;
        for (uint256 i = 0; i < _selectedCollectionIds.length; i++) {
            if (_selectedCollectionIds[i] > 0 && _galleries[i] > 0) {
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
        }

        (uint256[] memory _childIds, uint256 _parentId) = autographCollection
            .mintMix(_selectedCollectionIds, _galleries, _buyer);

        return (_childIds, _selectedCollectionIds, _parentId, _total);
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
        uint256 _count = 0;
        uint256 _total = 0;
        uint256 _attemptCount = 0;

        if (_availableCollectionIds.length <= 3) {
            _numNFTs = _availableCollectionIds.length;
        }

        uint256[] memory _selectedCollectionIds = new uint256[](_numNFTs);
        uint16[] memory _galleries = new uint16[](_numNFTs);

        while (_count < _numNFTs && _attemptCount < _numNFTs * 2) {
            uint256 index = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        _attemptCount
                    )
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
                _attemptCount++;
                continue;
            }

            uint16 _galleryId = autographData.getCollectionGallery(
                _selectedCollectionId
            );

            if (
                autographData.getAutographCurrencyIsAccepted(
                    _currency,
                    _selectedCollectionId
                ) &&
                _total +
                    autographData.getCollectionPriceByGalleryId(
                        _selectedCollectionId,
                        _galleryId
                    ) <=
                _maxAmount
            ) {
                _selectedCollectionIds[_count] = _selectedCollectionId;
                _galleries[_count] = _galleryId;
                _count++;
            }

            _attemptCount++;
        }

        if (_count < _numNFTs) {
            revert NoMixFound();
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
