// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/AutographData.sol";
import "../src/AutographNFT.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographCollection.sol";
import "../src/AutographOpenAction.sol";
import "../src/print/PrintSplitsData.sol";
import "../src/print/PrintAccessControl.sol";

contract AutographDataTest is Test {
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    PrintSplitsData public printSplitsData;
    AutographOpenAction public autographOpenAction;
    PrintAccessControl public printAccessControl;
    AutographNFT public autographNFT;

    address public owner = address(1);
    address public nonAdmin = address(2);
    address public mona = address(4);
    address public usdt = address(5);
    address public eth = address(6);
    address public matic = address(7);
    address public designer = address(8);
    address public hub = address(9);
    address public moduleGlobals = address(10);
    address public secondDesigner = address(11);

    bytes32 constant ADDRESS_NOT_VERIFIED_ERROR =
        keccak256("AddressNotVerified()");
    bytes32 constant ADDRESS_INVALID_ERROR = keccak256("InvalidAddress()");
    bytes32 constant GALLERY_DESIGNER_ERROR = keccak256("NotGalleryDesigner()");

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
            address(autographMarket)
        );

        autographOpenAction = new AutographOpenAction(
            "metadata",
            hub,
            moduleGlobals,
            address(autographData),
            address(accessControl),
            address(autographMarket)
        );

        autographCollection.setAutographData(address(autographData));
        autographCollection.setAutographMarket(address(autographMarket));
        autographMarket.setAutographCollection(address(autographCollection));
        autographMarket.setAutographData(address(autographData));
        autographNFT.setAutographData(address(autographData));
        autographNFT.setAutographMarketAddress(address(autographMarket));
        printSplitsData.addCurrency(matic, 1000000000000000000);
        printSplitsData.addCurrency(mona, 1000000000000000000);
        printSplitsData.addCurrency(eth, 1000000000000000000);
        printSplitsData.addCurrency(usdt, 1000000);
        printSplitsData.setOraclePriceUSD(matic, 772200000000000000);
        printSplitsData.setOraclePriceUSD(mona, 411150300000000000000);
        printSplitsData.setOraclePriceUSD(eth, 2077490000000000000000);
        printSplitsData.setOraclePriceUSD(usdt, 1000000000000000000);

        vm.prank(address(this));
        accessControl.addAdmin(owner);

        vm.prank(owner);
        accessControl.addOpenAction(address(autographOpenAction));

        vm.prank(owner);
        accessControl.addAdmin(nonAdmin);

        vm.prank(owner);
        accessControl.addDesigner(designer);

        vm.prank(owner);
        accessControl.addDesigner(secondDesigner);
    }

    function testCreateAutograph() public {
        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = eth;
        acceptedTokens[1] = usdt;
        acceptedTokens[2] = matic;
        string[] memory pages = new string[](4);
        pages[0] = "page1uri";
        pages[1] = "page2uri";
        pages[2] = "page3uri";
        pages[3] = "page4uri";

        AutographLibrary.OpenActionParams memory params = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 100000000000000000000,
                acceptedTokens: acceptedTokens,
                uri: "mainuri",
                amount: 500,
                pages: pages,
                pageCount: 4,
                collectionId: 0,
                galleryId: 0
            });

        bytes memory data = abi.encode(params);

        vm.prank(hub);
        autographOpenAction.initializePublicationAction(900, 120, owner, data);

        assertEq(autographData.getAutographAmount(), 500);
        assertEq(autographData.getAutographPrice(), 100000000000000000000);
        assertEq(autographData.getAutographURI(), "mainuri");
        assertEq(autographData.getAutographPageCount(), 4);
        assertEq(autographData.getAutographPage(1), "page1uri");
        assertEq(autographData.getAutographPage(2), "page2uri");
        assertEq(autographData.getAutographPage(3), "page3uri");
        assertEq(autographData.getAutographPage(4), "page4uri");
        assertEq(autographData.getAutographAcceptedTokens(), acceptedTokens);
        assertEq(autographData.getAutographDesigner(), owner);
        assertEq(autographData.getAutographProfileId(), 900);
        assertEq(autographData.getAutographPubId(), 120);

        vm.prank(hub);
        try
            autographOpenAction.initializePublicationAction(
                900,
                120,
                designer,
                data
            )
        {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_INVALID_ERROR));
        }
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
        prices[3] = 156900000000000000000;

        address[][] memory acceptedTokens = new address[][](4);
        acceptedTokens[0] = new address[](3);
        acceptedTokens[0][0] = mona;
        acceptedTokens[0][1] = eth;
        acceptedTokens[0][2] = usdt;
        acceptedTokens[1] = new address[](2);
        acceptedTokens[1][0] = mona;
        acceptedTokens[1][1] = usdt;
        acceptedTokens[2] = new address[](1);
        acceptedTokens[2][0] = matic;
        acceptedTokens[3] = new address[](3);
        acceptedTokens[3][0] = mona;
        acceptedTokens[3][1] = eth;
        acceptedTokens[3][2] = usdt;

        AutographLibrary.CollectionType[]
            memory collectionTypes = new AutographLibrary.CollectionType[](4);
        collectionTypes[0] = AutographLibrary.CollectionType.Print;
        collectionTypes[1] = AutographLibrary.CollectionType.Digital;
        collectionTypes[2] = AutographLibrary.CollectionType.Digital;
        collectionTypes[3] = AutographLibrary.CollectionType.Print;

        AutographLibrary.CollectionInit memory collectionInit = AutographLibrary
            .CollectionInit({
                uris: uris,
                amounts: amounts,
                prices: prices,
                acceptedTokens: acceptedTokens,
                collectionTypes: collectionTypes
            });

        vm.prank(designer);
        autographCollection.createGallery(collectionInit);

        vm.prank(owner);
        try autographCollection.createGallery(collectionInit) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_NOT_VERIFIED_ERROR));
        }

        return collectionInit;
    }

    function testCreateGalleryOne() public {
        AutographLibrary.CollectionInit
            memory _params = createInitialGalleryAndCollections();

        uint256 galleryCounter = autographData.getGalleryCounter();
        uint16[] memory galleries = autographData.getDesignerGalleries(
            designer
        );
        uint256 length = autographData.getGalleryLengthByDesigner(designer);
        address des = autographData.getCollectionDesignerByGalleryId(1, 1);
        string memory collectionOneUri = autographData
            .getCollectionURIByGalleryId(1, 1);
        string memory collectionTwoUri = autographData
            .getCollectionURIByGalleryId(2, 1);
        uint256 collectionCounter = autographData.getCollectionCounter();
        uint16[] memory galleriesExpected = new uint16[](1);
        galleriesExpected[0] = 1;

        assertEq(galleryCounter, 1);
        assertEq(collectionCounter, 4);
        assertEq(galleries.length, 1);
        assertEq(
            keccak256(abi.encodePacked((galleries))),
            keccak256(abi.encodePacked((galleriesExpected)))
        );
        assertEq(length, 1);
        assertEq(des, designer);
        assertEq(collectionOneUri, _params.uris[0]);
        assertEq(collectionTwoUri, _params.uris[1]);
    }

    function testCreateGalleryTwo() public {
        AutographLibrary.CollectionInit
            memory _params = createInitialGalleryAndCollections();

        uint256 collectionOneAmount = autographData
            .getCollectionAmountByGalleryId(1, 1);
        uint256 collectionThreeAmount = autographData
            .getCollectionAmountByGalleryId(3, 1);
        uint256 collectionOnePrice = autographData
            .getCollectionPriceByGalleryId(1, 1);
        uint256 collectionTwoPrice = autographData
            .getCollectionPriceByGalleryId(2, 1);
        address[] memory collectionOneTokens = autographData
            .getCollectionAcceptedTokensByGalleryId(1, 1);
        address[] memory collectionTwoTokens = autographData
            .getCollectionAcceptedTokensByGalleryId(2, 1);
        bool ethAcceptedCollectionOne = autographData
            .getAutographCurrencyIsAccepted(eth, 1);
        bool ethAcceptedCollectionThree = autographData
            .getAutographCurrencyIsAccepted(eth, 3);

        assertEq(collectionOneAmount, _params.amounts[0]);
        assertEq(collectionThreeAmount, _params.amounts[2]);
        assertEq(collectionOnePrice, _params.prices[0]);
        assertEq(collectionTwoPrice, _params.prices[1]);
        assertEq(collectionOneTokens, _params.acceptedTokens[0]);
        assertEq(collectionTwoTokens, _params.acceptedTokens[1]);
        assertEq(ethAcceptedCollectionOne, true);
        assertEq(ethAcceptedCollectionThree, false);
    }

    function testCreateGalleryThree() public {
        createInitialGalleryAndCollections();
        uint256[] memory minted = autographData.getMintedTokenIdsByGalleryId(
            1,
            1
        );
        uint256 collectionCount = autographData.getGalleryCollectionCount(1);
        uint256[] memory colls = autographData.getGalleryCollections(1);
        uint16 collectionOneGallery = autographData.getCollectionGallery(1);
        uint16 collectionThreeGallery = autographData.getCollectionGallery(3);
        uint256[] memory collsAvailable = autographData
            .getArtistCollectionsAvailable(designer);

        uint256[] memory collsExpected = new uint256[](4);
        collsExpected[0] = 1;
        collsExpected[1] = 2;
        collsExpected[2] = 3;
        collsExpected[3] = 4;

        assertEq(collectionCount, 4);
        assertEq(colls, collsExpected);
        assertEq(collectionOneGallery, 1);
        assertEq(collectionThreeGallery, 1);
        assertEq(collsAvailable, collsExpected);
        assertEq(minted.length, 0);
    }

    function testAddPubProfileCollection() public {
        createInitialGalleryAndCollections();

        AutographLibrary.OpenActionParams memory params = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 1,
                galleryId: 1
            });

        bytes memory data = abi.encode(params);
        vm.prank(hub);
        autographOpenAction.initializePublicationAction(
            900,
            450,
            designer,
            data
        );

        AutographLibrary.OpenActionParams memory paramsTwo = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 4,
                galleryId: 1
            });

        bytes memory dataTwo = abi.encode(paramsTwo);
        vm.prank(hub);
        autographOpenAction.initializePublicationAction(
            900,
            1543,
            designer,
            dataTwo
        );

        uint256 galleryCollectionOne = autographData.getGalleryByPublication(
            900,
            450
        );
        uint256 galleryCollectionFour = autographData.getGalleryByPublication(
            900,
            1543
        );
        uint256 collectionOne = autographData.getCollectionByPublication(
            900,
            450
        );
        uint256 collectionFour = autographData.getCollectionByPublication(
            900,
            1543
        );
        uint256[] memory collectionOneProfiles = autographData
            .getCollectionProfileIdsByGalleryId(1, 1);
        uint256[] memory collectionFourProfiles = autographData
            .getCollectionProfileIdsByGalleryId(4, 1);
        uint256[] memory collectionOnePubs = autographData
            .getCollectionPubIdsByGalleryId(1, 1);
        uint256[] memory collectionFourPubs = autographData
            .getCollectionPubIdsByGalleryId(4, 1);

        assertEq(galleryCollectionOne, 1);
        assertEq(galleryCollectionFour, 1);
        assertEq(collectionOne, 1);
        assertEq(collectionFour, 4);
        assertEq(collectionOneProfiles[0], 900);
        assertEq(collectionFourProfiles[0], 900);
        assertEq(collectionOnePubs[0], 450);
        assertEq(collectionFourPubs[0], 1543);
    }

    function testAddAndDeleteCollectionGallery() public {
        AutographLibrary.CollectionInit
            memory _params = createInitialGalleryAndCollections();

        vm.prank(designer);
        autographCollection.addCollections(_params, 1);

        uint256[] memory colls = autographData.getGalleryCollections(1);
        assertEq(colls.length, 8);

        vm.prank(designer);
        autographCollection.deleteCollection(3, 1);

        colls = autographData.getGalleryCollections(1);
        assertEq(colls.length, 7);

        vm.prank(designer);
        autographCollection.deleteCollection(7, 1);

        colls = autographData.getGalleryCollections(1);
        assertEq(colls.length, 6);

        vm.prank(owner);
        try autographCollection.addCollections(_params, 1) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_NOT_VERIFIED_ERROR));
        }

        vm.prank(secondDesigner);
        try autographCollection.deleteCollection(3, 1) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(GALLERY_DESIGNER_ERROR));
        }

        vm.prank(designer);
        autographCollection.deleteGallery(1);

        colls = autographData.getGalleryCollections(1);
        assertEq(colls.length, 0);
    }

    function testCatalogPurchase() public {}

    function testCatalogCollectionPurchase() public {}

    function testMixPurchase() public {}

    function testAllPurchase() public {}
}
