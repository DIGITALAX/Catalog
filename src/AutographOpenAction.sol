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
                    price: _autographCreator.price,
                    acceptedTokens: _autographCreator.acceptedTokens,
                    uri: _autographCreator.uri,
                    pubId: _pubId,
                    profileId: _profileId,
                    amount: _autographCreator.amount,
                    pages: _autographCreator.pages,
                    designer: _executor
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
                _autographCreator.price,
                _autographCreator.acceptedTokens
            );
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata _params
    ) external override onlyHub returns (bytes memory) {
        (
            string memory _encryptedFulfillment,
            address _currency,
            uint8 _quantity,
            AutographLibrary.AutographType _type
        ) = abi.decode(
                _params.actionModuleData,
                (string, address, uint8, AutographLibrary.AutographType)
            );

        if (!MODULE_GLOBALS.isErc20CurrencyRegistered(_currency)) {
            revert CurrencyNotWhitelisted();
        }

        uint256 _collectionId = autographData.getCollectionByPublication(
            _params.publicationActedProfileId,
            _params.publicationActedId
        );

        autographMarket.buyTokenAction(
            _encryptedFulfillment,
            _params.actorProfileOwner,
            _currency,
            _collectionId,
            _quantity,
            _type
        );

        return abi.encode(_type, _currency);
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
