// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/AutographData.sol";
import "../src/AutographNFT.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographCollection.sol";
import "../src/print/PrintSplitsData.sol";
import "../src/print/PrintAccessControl.sol";

contract AutographDataTest is Test {
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    PrintSplitsData public printSplitsData;
    PrintAccessControl public printAccessControl;
    AutographNFT public autographNFT;

    address public owner = address(1);
    address public nonAdmin = address(2);
    address public openAction = address(3);

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

        autographCollection.setAutographData(address(this));
        autographCollection.setAutographMarket(address(autographMarket));
        autographMarket.setAutographCollection(address(autographCollection));
        autographMarket.setAutographData(address(this));
        autographNFT.setAutographData(address(this));
        autographNFT.setAutographMarketAddress(address(autographMarket));

        vm.prank(address(this));
        accessControl.addAdmin(owner);

        vm.prank(owner);
        accessControl.addOpenAction(openAction);

        vm.prank(owner);
        accessControl.addAdmin(nonAdmin);
    }

    function testCreateAutograph() public {
        address[] memory acceptedTokens = new address[](1);
        acceptedTokens[0] = address(0);
        string[] memory pages = new string[](1);
        pages[0] = "https://example.com";

        AutographLibrary.AutographInit memory autographInit = AutographLibrary
            .AutographInit({
                uri: "http://example.com",
                amount: 10,
                price: 1 ether,
                acceptedTokens: acceptedTokens,
                designer: address(4),
                pubId: 1,
                profileId: 1,
                pages: pages,
                pageCount: 0
            });

        vm.prank(openAction);
        autographData.createAutograph(autographInit);

        assertEq(autographData.getAutographURI(), "http://example.com");
        assertEq(autographData.getAutographAmount(), 10);
        assertEq(autographData.getAutographPrice(), 1 ether);
    }

    function testCreateGallery() public {
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

        AutographLibrary.CollectionInit memory collectionInit = AutographLibrary
            .CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            });

        vm.prank(openAction);
        autographData.createGallery(collectionInit, address(4));

        uint256 galleryCounter = autographData.getGalleryCounter();
        assertEq(galleryCounter, 1);
        uint256[] memory collections = autographData.getGalleryCollections(
            uint16(galleryCounter)
        );
        assertEq(collections.length, 1);
    }

    function testAddCollections() public {
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

        AutographLibrary.CollectionInit memory collectionInit = AutographLibrary
            .CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            });
        collectionInit.uris[0] = "http://example.com/collection";
        collectionInit.amounts[0] = 5;
        collectionInit.prices[0] = 0.5 ether;
        collectionInit.acceptedTokens;
        collectionInit.collectionTypes[0] = AutographLibrary
            .CollectionType
            .Print;

        vm.prank(address(autographCollection));
        autographData.addCollections(collectionInit, address(4), 1);

        uint256[] memory collections = autographData.getGalleryCollections(1);
        assertEq(collections.length, 1);
    }

    function testConnectPublication() public {
        uint256 pubId = 1;
        uint256 profileId = 1;
        uint256 collectionId = 1;
        uint16 galleryId = 1;

        vm.prank(openAction);
        autographData.connectPublication(
            pubId,
            profileId,
            collectionId,
            galleryId
        );

        assertEq(
            autographData.getCollectionByPublication(profileId, pubId),
            collectionId
        );
        assertEq(
            autographData.getGalleryByPublication(profileId, pubId),
            galleryId
        );
    }

    function testDeleteGallery() public {
        vm.prank(address(autographCollection));
        autographData.deleteGallery(address(4), 1);

        uint256[] memory collections = autographData.getGalleryCollections(1);
        assertEq(collections.length, 0);
    }

    function testDeleteCollection() public {
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

        AutographLibrary.CollectionInit memory collectionInit = AutographLibrary
            .CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            });
        collectionInit.uris[0] = "http://example.com/collection";
        collectionInit.amounts[0] = 5;
        collectionInit.prices[0] = 0.5 ether;
        collectionInit.acceptedTokens;
        collectionInit.collectionTypes[0] = AutographLibrary
            .CollectionType
            .Print;

        vm.prank(address(autographCollection));
        autographData.addCollections(collectionInit, address(4), 1);
        vm.prank(address(autographCollection));

        autographData.deleteCollection(1, 1);

        uint256[] memory collections = autographData.getGalleryCollections(1);
        assertEq(collections.length, 0);
    }

    function testSetMintedTokens() public {
        uint256 tokenId = 1;
        uint256 collectionId = 1;
        uint16 galleryId = 1;

        vm.prank(address(autographCollection));
        autographData.setMintedTokens(tokenId, collectionId, galleryId);

        uint256[] memory mintedTokenIds = autographData
            .getMintedTokenIdsByGalleryId(collectionId, galleryId);
        assertEq(mintedTokenIds[0], tokenId);
    }

    function testSetVig() public {
        vm.prank(owner);
        autographData.setVig(5);

        assertEq(autographData.getVig(), 5);
    }

    function testSetHoodieBase() public {
        vm.prank(owner);
        autographData.setHoodieBase(5);

        assertEq(autographData.getHoodieBase(), 5);
    }

    function testSetShirtBase() public {
        vm.prank(owner);
        autographData.setShirtBase(5);

        assertEq(autographData.getShirtBase(), 5);
    }

    function testGetAutographURI() public {
        assertEq(autographData.getAutographURI(), "");
    }

    function testGetDesignerGalleries() public {
        uint16[] memory galleries = autographData.getDesignerGalleries(
            address(4)
        );
        assertEq(galleries.length, 0);
    }

    // Continue adding tests for all other view functions and modifiers

    function testGetGalleryLengthByDesigner() public {
        uint256 length = autographData.getGalleryLengthByDesigner(address(4));
        assertEq(length, 0);
    }

    function testGetGalleryEditable() public {
        bool editable = autographData.getGalleryEditable(1);
        assertEq(editable, false);
    }

    function testGetCollectionDesignerByGalleryId() public {
        address designer = autographData.getCollectionDesignerByGalleryId(1, 1);
        assertEq(designer, address(0));
    }

    function testGetCollectionURIByGalleryId() public {
        string memory uri = autographData.getCollectionURIByGalleryId(1, 1);
        assertEq(uri, "");
    }

    function testGetCollectionAmountByGalleryId() public {
        uint256 amount = autographData.getCollectionAmountByGalleryId(1, 1);
        assertEq(amount, 0);
    }

    function testGetCollectionPriceByGalleryId() public {
        uint256 price = autographData.getCollectionPriceByGalleryId(1, 1);
        assertEq(price, 0);
    }

    function testGetCollectionAcceptedTokensByGalleryId() public {
        address[] memory tokens = autographData
            .getCollectionAcceptedTokensByGalleryId(1, 1);
        assertEq(tokens.length, 0);
    }

    function testGetCollectionProfileIdsByGalleryId() public {
        uint256[] memory profileIds = autographData
            .getCollectionProfileIdsByGalleryId(1, 1);
        assertEq(profileIds.length, 0);
    }

    function testGetCollectionPubIdsByGalleryId() public {
        uint256[] memory pubIds = autographData.getCollectionPubIdsByGalleryId(
            1,
            1
        );
        assertEq(pubIds.length, 0);
    }

    function testGetCollectionTypeByGalleryId() public {
        AutographLibrary.CollectionType collectionType = autographData
            .getCollectionTypeByGalleryId(1, 1);
        assertEq(
            uint8(collectionType),
            uint8(AutographLibrary.CollectionType.Print)
        );
    }

    function testGetCollectionByPublication() public {
        uint256 collection = autographData.getCollectionByPublication(1, 1);
        assertEq(collection, 0);
    }

    function testGetGalleryByPublication() public {
        uint16 gallery = autographData.getGalleryByPublication(1, 1);
        assertEq(gallery, 0);
    }

    function testGetMintedTokenIdsByGalleryId() public {
        uint256[] memory mintedTokenIds = autographData
            .getMintedTokenIdsByGalleryId(1, 1);
        assertEq(mintedTokenIds.length, 0);
    }

    function testGetAutographCurrencyIsAccepted() public {
        bool accepted = autographData.getAutographCurrencyIsAccepted(
            address(5),
            1
        );
        assertEq(accepted, false);
    }

    function testGetGalleryCollectionCount() public {
        uint256 count = autographData.getGalleryCollectionCount(1);
        assertEq(count, 0);
    }

    function testGetGalleryCollections() public {
        uint256[] memory collections = autographData.getGalleryCollections(1);
        assertEq(collections.length, 0);
    }

    function testGetCollectionGallery() public {
        uint16 gallery = autographData.getCollectionGallery(1);
        assertEq(gallery, 0);
    }

    function testGetNFTMix() public {
        uint256[] memory nftMix = autographData.getNFTMix();
        assertEq(nftMix.length, 0);
    }

    function testGetArtistCollectionsAvailable() public {
        uint256[] memory collections = autographData
            .getArtistCollectionsAvailable(address(4));
        assertEq(collections.length, 0);
    }

    function testGetCollectionCounter() public {
        uint256 counter = autographData.getCollectionCounter();
        assertEq(counter, 0);
    }

    function testGetGalleryCounter() public {
        uint256 counter = autographData.getGalleryCounter();
        assertEq(counter, 0);
    }

    function testGetAllArtists() public {
        address[] memory artists = autographData.getAllArtists();
        assertEq(artists.length, 0);
    }

    function testGetVig() public {
        uint256 vig = autographData.getVig();
        assertEq(vig, 0);
    }

    function testGetHoodieBase() public {
        uint256 hoodieBase = autographData.getHoodieBase();
        assertEq(hoodieBase, 0);
    }

    function testGetShirtBase() public {
        uint256 shirtBase = autographData.getShirtBase();
        assertEq(shirtBase, 0);
    }
}
