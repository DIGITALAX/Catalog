// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./CatalogAccessControl.sol";
import "./CatalogLibrary.sol";
import "./CatalogData.sol";

import {HubRestricted} from "./../lens/v2/base/HubRestricted.sol";
import {Types} from "./../lens/v2/libraries/constants/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPublicationActionModule} from "./../lens/v2/interfaces/IPublicationActionModule.sol";
import {ILensModule} from "./../lens/v2/interfaces/ILensModule.sol";
import {IModuleRegistry} from "./../lens/v2/interfaces/IModuleRegistry.sol";

contract CatalogOpenAction is
    HubRestricted,
    ILensModule,
    IPublicationActionModule
{
    string private _metadata;

    constructor(
        string memory _metadataDetails,
        address _hub,
        address _moduleGlobals
    ) HubRestricted(_hub) {
        MODULE_GLOBALS = IModuleRegistry(_moduleGlobals);
        _metadata = _metadataDetails;
    }

    function initializePublicationAction(
        uint256 _profileId,
        uint256 _pubId,
        address _executor,
        bytes calldata _data
    ) external override onlyHub returns (bytes memory) {
        CatalogLibrary.CatalogInitParams memory _catalogCreator = abi.decode(
            _data,
            (CatalogLibrary.CatalogInitParams)
        );

        if (
            _catalogCreator.catalogType == CatalogLibrary.CatalogType.Print
        ) {

            
                
        } else {}

        return
            abi.encode(
                _catalogCreator.catalogType,
                _catalogCreator.amount,
                _catalogCreator.uri,
                _catalogCreator.prices,
                _catalogCreator.acceptedTokens
            );
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata _params
    ) external override onlyHub returns (bytes memory) {
        /// procede el tipo de compra
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
