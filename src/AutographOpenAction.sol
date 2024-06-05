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
    AutographData public autographData;
    AutographAccessControl public autographAccessControl;
    AutographMarket public autographMarket;
    string private _metadata;

    error CurrencyNotWhitelisted();
    error InvalidAddress();
    error ExceedAmount();

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
                autographData.getCollectionDesignerByGalleryId(
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
            uint8[] memory _quantities,
            uint8[] memory _chosenIndexes,
            address[] memory _currencies,
            AutographLibrary.AutographType[] memory _types,
            string memory _encryptedFulfillment
        ) = abi.decode(
                _params.actionModuleData,
                (
                    uint8[],
                    uint8[],
                    address[],
                    AutographLibrary.AutographType[],
                    string
                )
            );

        for (uint8 i = 0; i < _currencies.length; i++) {
            address _currency = _currencies[i];

            if (!MODULE_GLOBALS.isErc20CurrencyRegistered(_currency)) {
                revert CurrencyNotWhitelisted();
            }
        }

        uint16 _galleryId = autographData.getGalleryByPublication(
            _params.publicationActedProfileId,
            _params.publicationActedId
        );
        uint256[] memory _collections = autographData.getGalleryCollections(
            _galleryId
        );

        for (uint256 j = 0; j < _collections.length; j++) {
            address[] memory acceptedTokens = autographData
                .getCollectionAcceptedTokensByGalleryId(
                    _collections[j],
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
        }

        uint256 _collectionId = autographData.getCollectionByPublication(
            _params.publicationActedProfileId,
            _params.publicationActedId
        );

        uint256[] memory _collectionIds = new uint256[](1);
        _collectionIds[0] = _collectionId;

        autographMarket.buyTokens(
            _currencies,
            _collectionIds,
            _quantities,
            _chosenIndexes,
            _types,
            _encryptedFulfillment,
            _params.actorProfileOwner
        );

        return abi.encode(_types, _currencies, _chosenIndexes);
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
