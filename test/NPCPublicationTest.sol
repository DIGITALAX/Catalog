// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/NPCPublication.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographData.sol";

contract NPCPublicationTest is Test {
    NPCPublication public npcPublication;
    AutographAccessControl public accessControl;
    AutographData public autographData;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    PrintSplitsData public printSplitsData;
    PrintAccessControl public printAccessControl;
    AutographNFT public autographNFT;

    address admin = address(0x1);
    address npc = address(0x2);
    address artist = address(0x3);
    address nonNpc = address(0x4);

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
            address(autographCollection)
        );
        npcPublication = new NPCPublication(
            "NPCP",
            "NPC Publication",
            address(accessControl),
            address(autographCollection)
        );

        autographCollection.setAutographData(address(this));
        autographCollection.setAutographMarket(address(autographMarket));
        autographMarket.setAutographCollection(address(autographCollection));
        autographMarket.setAutographData(address(this));
        autographNFT.setAutographData(address(this));
        autographNFT.setAutographMarketAddress(address(autographMarket));

        accessControl.addAdmin(admin);
        accessControl.addNPC(npc);
    }

    function testInitialSetup() public {
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

    function testGetPublicationPredictByNPC() public {
        string[] memory uris = new string[](1);
        uris[0] = "https://example.com";

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256[] memory prices = new uint256[](1);
        prices[0] = 1 ether;

        address[][] memory acceptedTokens = new address[][](1);
        acceptedTokens[0] = new address[](1);
        acceptedTokens[0][0] = address(0);

        AutographLibrary.CollectionType[]
            memory collectionTypes = new AutographLibrary.CollectionType[](1);
        collectionTypes[0] = AutographLibrary.CollectionType.Print;

        vm.prank(address(autographCollection));
        autographData.createGallery(
            AutographLibrary.CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            }),
            artist
        );

        vm.prank(npc);
        npcPublication.registerPublication(
            artist,
            1,
            1,
            1,
            AutographLibrary.LensType.Autograph
        );

        (
            AutographLibrary.LensType lensType,
            address _artist,
            uint8 page
        ) = npcPublication.getPublicationPredictByNPC(npc);
    }
}
