// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.26;

// import "forge-std/Test.sol";
// import "../src/AutographOpenAction.sol";
// import "../src/AutographData.sol";
// import "../src/AutographAccessControl.sol";
// import "../src/AutographMarket.sol";
// import "../src/lens/v2/interfaces/IModuleRegistry.sol";

// contract AutographOpenActionTest is Test {
//     AutographOpenAction autographOpenAction;
//     AutographData autographData;
//     AutographMarket autographMarket;
//     IModuleRegistry moduleRegistry;
//     AutographAccessControl accessControl;
//     AutographCollection autographCollection;
//     PrintSplitsData printSplitsData;
//     PrintAccessControl printAccessControl;
//     AutographNFT autographNFT;

//     address hub = address(0x1);
//     address moduleGlobals = address(0x2);
//     address autographDataAddress = address(0x3);
//     address autographAccessControlAddress = address(0x4);
//     address autographMarketAddress = address(0x5);
//     address admin = address(0x6);
//     address artist = address(0x7);

//     string metadata = "metadata URI";

//     function setUp() public {
//         accessControl = new AutographAccessControl();
//         printAccessControl = new PrintAccessControl();
//         printSplitsData = new PrintSplitsData(address(printAccessControl));
//         autographNFT = new AutographNFT(address(accessControl));
//         autographMarket = new AutographMarket(
//             "AMAR",
//             "Autograph Market",
//             address(accessControl),
//             address(printSplitsData),
//             address(autographNFT)
//         );
//         autographCollection = new AutographCollection(address(accessControl));
//         autographData = new AutographData(
//             "ADATA",
//             "Autograph Data",
//             address(accessControl),
//             address(autographCollection),
//             address(autographMarket)
//         );

//         autographCollection.setAutographData(address(this));
//         autographCollection.setAutographMarket(address(autographMarket));
//         autographMarket.setAutographCollection(address(autographCollection));
//         autographMarket.setAutographData(address(this));
//         autographNFT.setAutographData(address(this));
//         autographNFT.setAutographMarketAddress(address(autographMarket));

//         moduleRegistry = IModuleRegistry(moduleGlobals);

//         autographOpenAction = new AutographOpenAction(
//             metadata,
//             hub,
//             moduleGlobals,
//             address(autographData),
//             address(accessControl),
//             address(autographMarket)
//         );

//         accessControl.addDesigner(artist);
//         accessControl.addOpenAction(address(autographOpenAction));
//     }

//     function testInitializePublicationAction() public {
//         uint256 profileId = 1;
//         uint256 pubId = 1;
//         address executor = address(this);

//         AutographLibrary.OpenActionParams memory params = AutographLibrary
//             .OpenActionParams({
//                 autographType: AutographLibrary.AutographType.Catalog,
//                 price: 1 ether,
//                 acceptedTokens: new address[](1),
//                 uri: "testURI",
//                 amount: 1,
//                 pages: new string[](1),
//                 pageCount: 1,
//                 collectionId: 1,
//                 galleryId: 1
//             });
//         params.acceptedTokens[0] = address(0);
//         params.pages[0] = "exampleuri.com";

//         bytes memory data = abi.encode(params);

//         vm.startPrank(hub);
//         bytes memory result = autographOpenAction.initializePublicationAction(
//             profileId,
//             pubId,
//             executor,
//             data
//         );
//         vm.stopPrank();

//         (
//             AutographLibrary.AutographType autographType,
//             uint256 amount,
//             string memory uri,
//             uint256 price,
//             address[] memory acceptedTokens
//         ) = abi.decode(
//                 result,
//                 (
//                     AutographLibrary.AutographType,
//                     uint256,
//                     string,
//                     uint256,
//                     address[]
//                 )
//             );

//         assertEq(uint256(autographType), uint256(params.autographType));
//         assertEq(amount, params.amount);
//         assertEq(uri, params.uri);
//         assertEq(price, params.price);
//         assertEq(acceptedTokens[0], params.acceptedTokens[0]);
//     }

//     function testProcessPublicationAction() public {
//         Types.ProcessActionParams memory params = Types.ProcessActionParams({
//             actorProfileOwner: admin,
//             actorProfileId: 2,
//             actionModuleData: abi.encode(
//                 "encrypted",
//                 address(0),
//                 uint8(1),
//                 AutographLibrary.AutographType.Catalog
//             ),
//             publicationActedProfileId: 1,
//             publicationActedId: 1,
//             transactionExecutor: artist,
//             referrerProfileIds: new uint256[](0),
//             referrerPubIds: new uint256[](0),
//             referrerPubTypes: new Types.PublicationType[](0)
//         });

//         vm.startPrank(hub);
//         bytes memory result = autographOpenAction.processPublicationAction(
//             params
//         );
//         // vm.stopPrank();

//         // (AutographLibrary.AutographType autographType, address currency) = abi
//         //     .decode(result, (AutographLibrary.AutographType, address));

//         // assertEq(
//         //     uint256(autographType),
//         //     uint256(AutographLibrary.AutographType.Catalog)
//         // );
//         // assertEq(currency, address(0));
//     }

//     function testSupportsInterface() public {
//         bool supportsLensModule = autographOpenAction.supportsInterface(
//             bytes4(keccak256(abi.encodePacked("LENS_MODULE")))
//         );
//         bool supportsPublicationActionModule = autographOpenAction
//             .supportsInterface(type(IPublicationActionModule).interfaceId);

//         assertTrue(supportsLensModule);
//         assertTrue(supportsPublicationActionModule);
//     }

//     function testGetModuleMetadataURI() public {
//         string memory uri = autographOpenAction.getModuleMetadataURI();
//         assertEq(uri, metadata);
//     }

//     function testConstructor() public {
//         assertEq(address(autographOpenAction.MODULE_GLOBALS()), moduleGlobals);
//         assertEq(autographOpenAction.getModuleMetadataURI(), metadata);
//         assertEq(
//             address(autographOpenAction.autographData()),
//             address(autographData)
//         );
//         assertEq(
//             address(autographOpenAction.autographAccessControl()),
//             address(accessControl)
//         );
//         assertEq(
//             address(autographOpenAction.autographMarket()),
//             address(autographMarket)
//         );
//     }
// }
