// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographData.sol";
import "./AutographMarket.sol";

import {HubRestricted} from "./lens/v2/base/HubRestricted.sol";
import {Types} from "./lens/v2/libraries/constants/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPublicationActionModule} from "./lens/v2/interfaces/IPublicationActionModule.sol";
import {ILensModule} from "./lens/v2/interfaces/ILensModule.sol";
import {IModuleRegistry} from "./lens/v2/interfaces/IModuleRegistry.sol";

contract AutographOpenAction is
    HubRestricted,
    ILensModule,
    IPublicationActionModule
{
    AutographData private autographData;
    AutographAccessControl private autographAccessControl;
    AutographMarket private autographMarket;
    string private _metadata;

    error CurrencyNotWhitelisted();
    error InvalidAddress();

    IModuleRegistry public immutable MODULE_GLOBALS;

    mapping(uint256 => mapping(uint256 => uint256)) _catalogGroups;

    constructor(
        string memory _metadataDetails,
        address _hub,
        address _moduleGlobals,
        address _autographDataAddress,
        address _autographAccessControlAddress,
        address _autographMarketAddress
    ) HubRestricted(_hub) {
        MODULE_GLOBALS = IModuleRegistry(_moduleGlobals);
        autographData = AutographData(_autographDataAddress);
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
        autographMarket = AutographMarket(_autographMarketAddress);
        _metadata = _metadataDetails;
    }

    function initializePublicationAction(
        uint256 _profileId,
        uint256 _pubId,
        address _executor,
        bytes calldata _data
    ) external override onlyHub returns (bytes memory) {
        AutographLibrary.OpenActionParams memory _autographCreator = abi.decode(
            _data,
            (AutographLibrary.OpenActionParams)
        );

        if (
            _autographCreator.autographType ==
            AutographLibrary.AutographType.Catalog &&
            autographAccessControl.isAdmin(_executor)
        ) {
            autographData.createAutograph(
                AutographLibrary.AutographInit({
                    prices: _autographCreator.prices,
                    acceptedTokens: _autographCreator.acceptedTokens,
                    uri: _autographCreator.uri,
                    pubId: _pubId,
                    profileId: _profileId,
                    amount: _autographCreator.amount
                })
            );
        } else if (autographAccessControl.isDesigner(_executor)) {
            if (
                autographData.getCollectionDesignerByGallery(
                    _autographCreator.collectionId,
                    _autographCreator.galleryId
                ) !=
                msg.sender &&
                !autographAccessControl.isNPC(msg.sender)
            ) {
                revert InvalidAddress();
            }

            autographData.connectPublication(
                _pubId,
                _profileId,
                _autographCreator.collectionId,
                _autographCreator.galleryId
            );
        }

        return
            abi.encode(
                _autographCreator.autographType,
                _autographCreator.amount,
                _autographCreator.uri,
                _autographCreator.prices,
                _autographCreator.acceptedTokens
            );
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata _params
    ) external override onlyHub returns (bytes memory) {
        (
            uint256[] memory _chosenIndexes,
            uint256[] memory _quantities,
            AutographLibrary.AutographType[] memory _types,
            string memory _encryptedFulfillment,
            address _currency
        ) = abi.decode(
                _params.actionModuleData,
                (
                    uint256[],
                    uint256[],
                    string,
                    address,
                    AutographLibrary.AutographType
                )
            );

        if (!MODULE_GLOBALS.isErc20CurrencyRegistered(_currency)) {
            revert CurrencyNotWhitelisted();
        }

        uint256 _grandTotal = _managePurchase(
            _params,
            _currency,
            _types,
            _chosenIndexes,
            _quantities
        );

        autographMarket.buyTokens(_buyTokensParams);

        return abi.encode(_types, _currency, _chosenIndexes);
    }

    function _managePurchase(
        Types.ProcessActionParams calldata _params,
        uint256[] memory _quantities,
        uint256[] memory _chosenIndexes,
        AutographLibrary.AutographType[] memory _types,
        address _currency
    ) internal returns (uint256, bool) {
        uint256 _total = 0;
        for (uint256 i = 0; i < _chosenIndexes.length; i++) {
            if (
                !autographData.getIsCollectionTokenAccepted(
                    _collectionId,
                    _currency
                )
            ) {
                revert CurrencyNotWhitelisted();
            }

            if (
                printDesignData.getCollectionTokensMinted(_collectionId) +
                    _quantities[i] >
                printDesignData.getCollectionAmount(_collectionId)
            ) {
                revert ExceedAmount();
            }

            _total = _transferTokens(
                _collectionId,
                _chosenIndexes[i],
                _quantities[i],
                _currency,
                printDesignData.getCollectionCreator(_collectionId),
                _buyer
            );
        }

        return _total;
    }

    function _transferTokens(
        uint256 _collectionId,
        uint256 _chosenIndex,
        uint256 _chosenAmount,
        address _chosenCurrency,
        address _designer,
        address _buyer
    ) internal returns (uint256) {
        uint256 _printType = printDesignData.getCollectionPrintType(
            _collectionId
        );

        if (_collectionId == 0) {
            // mintea al catalogo
        } else
            uint256 _totalPrice = printDesignData.getCollectionPrices(
                _collectionId
            )[_chosenIndex] * _chosenAmount;

        uint256 _calculatedPrice = _calculateAmount(
            _chosenCurrency,
            _totalPrice
        );
        uint256 _calculatedBase = _calculateAmount(
            _chosenCurrency,
            _fulfillerBase * _chosenAmount
        );

        uint256 _fulfillerAmount = _calculatedBase +
            ((_fulfillerSplit * _calculatedPrice) / 1e20);

        if (_fulfillerAmount > 0) {
            IERC20(_chosenCurrency).transferFrom(
                _buyer,
                _fulfiller,
                _fulfillerAmount
            );
        }

        if ((_calculatedPrice - _fulfillerAmount) > 0) {
            IERC20(_chosenCurrency).transferFrom(
                _buyer,
                _designer,
                _calculatedPrice - _fulfillerAmount
            );
        }

        return _calculatedPrice;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool) {
        return
            interfaceId == bytes4(keccak256(abi.encodePacked("LENS_MODULE"))) ||
            interfaceId == type(IPublicationActionModule).interfaceId;
    }

    function getModuleMetadataURI()
        external
        view
        override
        returns (string memory)
    {
        return _metadata;
    }
}
