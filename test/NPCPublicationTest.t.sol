// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/NPCPublication.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographData.sol";
import "../src/TestERC20.sol";
import "../src/AutographOpenAction.sol";

contract NPCPublicationTest is Test {
    NPCPublication public npcPublication;
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    PrintSplitsData public printSplitsData;
    PrintAccessControl public printAccessControl;
    AutographOpenAction public autographOpenAction;
    AutographNFT public autographNFT;
    TestERC20 public mona;
    TestERC20 public usdt;
    TestERC20 public eth;
    TestERC20 public matic;

    address admin = address(1);
    address npc = address(2);
    address artist = address(3);
    address nonNpc = address(4);
    address public owner = address(5);
    address public nonAdmin = address(6);
    address public buyer = address(7);
    address public fulfiller = address(8);
    address public hub = address(9);
    address public moduleGlobals = address(10);

    function setUp() public {
        accessControl = new AutographAccessControl();
        printAccessControl = new PrintAccessControl();
        printSplitsData = new PrintSplitsData(address(printAccessControl));
        autographNFT = new AutographNFT(address(accessControl));
        autographMarket = new AutographMarket(
            "AMAR",
            "Autograph Market",
            address(accessControl),
            address(printSplitsData),
            address(autographNFT)
        );

        autographCollection = new AutographCollection(address(accessControl));
        autographData = new AutographData(
            "ADATA",
            "Autograph Data",
            address(accessControl),
            address(autographCollection),
            address(autographMarket),
            address(autographNFT)
        );
        npcPublication = new NPCPublication(
            "NPCP",
            "NPC Publication",
            address(accessControl),
            address(autographCollection)
        );
        autographOpenAction = new AutographOpenAction(
            "metadata",
            hub,
            moduleGlobals,
            address(autographData),
            address(accessControl),
            address(autographMarket)
        );
        eth = new TestERC20();
        mona = new TestERC20();
        usdt = new TestERC20();
        matic = new TestERC20();

        accessControl.setFulfiller(fulfiller);
        autographData.setShirtBase(50000000000000000000);
        autographData.setHoodieBase(60000000000000000000);
        autographData.setVig(5);
        autographCollection.setAutographData(address(autographData));
        autographCollection.setAutographMarket(address(autographMarket));
        autographMarket.setAutographCollection(address(autographCollection));
        autographMarket.setAutographData(address(autographData));
        autographNFT.setAutographData(address(autographData));
        autographNFT.setAutographMarketAddress(address(autographMarket));
        printSplitsData.addCurrency(address(matic), 1000000000000000000);
        printSplitsData.addCurrency(address(mona), 1000000000000000000);
        printSplitsData.addCurrency(address(eth), 1000000000000000000);
        printSplitsData.addCurrency(address(usdt), 1000000);
        printSplitsData.setOraclePriceUSD(address(matic), 772200000000000000);
        printSplitsData.setOraclePriceUSD(address(mona), 411150300000000000000);
        printSplitsData.setOraclePriceUSD(address(eth), 2077490000000000000000);
        printSplitsData.setOraclePriceUSD(address(usdt), 1000000000000000000);

        vm.prank(address(this));
        accessControl.addAdmin(owner);

        vm.prank(owner);
        accessControl.addAdmin(nonAdmin);

        vm.prank(owner);
        accessControl.addDesigner(artist);

        vm.prank(owner);
        accessControl.addNPC(npc);

        vm.prank(owner);
        accessControl.addOpenAction(address(autographOpenAction));
    }

    function testInitialSetup() public view {
        assertEq(npcPublication.symbol(), "NPCP");
        assertEq(npcPublication.name(), "NPC Publication");
    }

    function testRegisterPublication() public {
        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            1,
            1,
            1,
            AutographLibrary.LensType.Autograph
        );

        assertEq(
            uint(npcPublication.getPublicationType(1, 1)),
            uint(AutographLibrary.LensType.Autograph)
        );
        assertEq(npcPublication.getPublicationArtist(1, 1), artist);
        assertEq(npcPublication.getPublicationNPC(1, 1), npc);
    }

    function testRegisterPublicationRevertsIfNotNPC() public {
        vm.prank(nonNpc);
        try
            npcPublication.registerPublication(
                artist,
                1,
                1,
                1,
                AutographLibrary.LensType.Autograph
            )
        {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(keccak256("AddressInvalid()")));
        }
    }

    function testGetPublicationType() public {
        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            1,
            1,
            1,
            AutographLibrary.LensType.Autograph
        );

        assertEq(
            uint(npcPublication.getPublicationType(1, 1)),
            uint(AutographLibrary.LensType.Autograph)
        );
    }

    function testGetPublicationArtist() public {
        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            1,
            1,
            1,
            AutographLibrary.LensType.Autograph
        );

        assertEq(npcPublication.getPublicationArtist(1, 1), artist);
    }

    function testGetPublicationNPC() public {
        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            1,
            1,
            1,
            AutographLibrary.LensType.Autograph
        );

        assertEq(npcPublication.getPublicationNPC(1, 1), npc);
    }

    function createInitialGalleryAndCollections()
        internal
        returns (AutographLibrary.CollectionInit memory)
    {
        string[] memory uris = new string[](4);
        uris[0] = "collectiononeuri";
        uris[1] = "collectiontwouri";
        uris[2] = "collectionthreeuri";
        uris[3] = "collectionfoururi";

        uint8[] memory amounts = new uint8[](4);
        amounts[0] = 10;
        amounts[1] = 1;
        amounts[2] = 7;
        amounts[3] = 20;

        uint256[] memory prices = new uint256[](4);
        prices[0] = 100000000000000000000;
        prices[1] = 180000000000000000000;
        prices[2] = 200000000000000000000;
        prices[3] = 300000000000000000000;

        address[][] memory acceptedTokens = new address[][](4);
        acceptedTokens[0] = new address[](3);
        acceptedTokens[0][0] = address(mona);
        acceptedTokens[0][1] = address(eth);
        acceptedTokens[0][2] = address(usdt);
        acceptedTokens[1] = new address[](2);
        acceptedTokens[1][0] = address(mona);
        acceptedTokens[1][1] = address(usdt);
        acceptedTokens[2] = new address[](2);
        acceptedTokens[2][0] = address(matic);
        acceptedTokens[2][1] = address(usdt);
        acceptedTokens[3] = new address[](3);
        acceptedTokens[3][0] = address(mona);
        acceptedTokens[3][1] = address(eth);
        acceptedTokens[3][2] = address(usdt);

        AutographLibrary.AutographType[]
            memory collectionTypes = new AutographLibrary.AutographType[](4);
        collectionTypes[0] = AutographLibrary.AutographType.Hoodie;
        collectionTypes[1] = AutographLibrary.AutographType.NFT;
        collectionTypes[2] = AutographLibrary.AutographType.NFT;
        collectionTypes[3] = AutographLibrary.AutographType.Shirt;

        AutographLibrary.CollectionInit memory collectionInit = AutographLibrary
            .CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            });

        vm.prank(artist);
        autographCollection.createGallery(collectionInit);

        return collectionInit;
    }

    function testGetPublicationPredictByNPC() public {
        // AutographLibrary.CollectionInit
        //     memory _params = createInitialGalleryAndCollections();

        vm.prank(npc);
        npcPublication.registerPublication(
            owner,
            500,
            134,
            1,
            AutographLibrary.LensType.Catalog
        );

        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            230,
            121,
            0,
            AutographLibrary.LensType.Autograph
        );

        (
            AutographLibrary.LensType lensType,
            address _artist,
            uint8 page
        ) = npcPublication.getPublicationPredictByNPC(npc);
    }
}
