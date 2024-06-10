// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/AutographData.sol";
import "../src/AutographNFT.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographCollection.sol";
import "../src/AutographOpenAction.sol";
import "../src/print/PrintSplitsData.sol";
import "../src/print/PrintAccessControl.sol";
import "../src/TestERC20.sol";

contract AutographDataTest is Test {
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    PrintSplitsData public printSplitsData;
    AutographOpenAction public autographOpenAction;
    PrintAccessControl public printAccessControl;
    AutographNFT public autographNFT;
    TestERC20 public mona;
    TestERC20 public usdt;
    TestERC20 public eth;
    TestERC20 public matic;

    address public owner = address(1);
    address public nonAdmin = address(2);
    address public designer = address(8);
    address public hub = address(9);
    address public moduleGlobals = address(10);
    address public secondDesigner = address(11);
    address public buyer = address(12);
    address public fulfiller = address(13);

    bytes32 constant ADDRESS_NOT_VERIFIED_ERROR =
        keccak256("AddressNotVerified()");
    bytes32 constant ADDRESS_INVALID_ERROR = keccak256("InvalidAddress()");
    bytes32 constant GALLERY_DESIGNER_ERROR = keccak256("NotGalleryDesigner()");
    bytes32 constant EXCEED_AMOUNT_ERROR = keccak256("ExceedAmount()");

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
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(matic);
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

        uint16[] memory galleriesExpected = new uint16[](1);
        galleriesExpected[0] = 1;

        assertEq(autographData.getGalleryCounter(), 1);
        assertEq(autographData.getCollectionCounter(), 4);
        assertEq(autographData.getDesignerGalleries(designer).length, 1);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getDesignerGalleries(designer)))
            ),
            keccak256(abi.encodePacked((galleriesExpected)))
        );
        assertEq(autographData.getGalleryLengthByDesigner(designer), 1);
        assertEq(
            autographData.getCollectionDesignerByGalleryId(1, 1),
            designer
        );
        assertEq(
            autographData.getCollectionURIByGalleryId(1, 1),
            _params.uris[0]
        );
        assertEq(
            autographData.getCollectionURIByGalleryId(2, 1),
            _params.uris[1]
        );
    }

    function testCreateGalleryTwo() public {
        AutographLibrary.CollectionInit
            memory _params = createInitialGalleryAndCollections();

        assertEq(
            autographData.getCollectionAmountByGalleryId(1, 1),
            _params.amounts[0]
        );
        assertEq(
            autographData.getCollectionAmountByGalleryId(3, 1),
            _params.amounts[2]
        );
        assertEq(
            autographData.getCollectionPriceByGalleryId(1, 1),
            _params.prices[0]
        );
        assertEq(
            autographData.getCollectionPriceByGalleryId(2, 1),
            _params.prices[1]
        );
        assertEq(
            autographData.getCollectionAcceptedTokensByGalleryId(1, 1),
            _params.acceptedTokens[0]
        );
        assertEq(
            autographData.getCollectionAcceptedTokensByGalleryId(2, 1),
            _params.acceptedTokens[1]
        );
        assertEq(
            autographData.getAutographCurrencyIsAccepted(address(eth), 1),
            true
        );
        assertEq(
            autographData.getAutographCurrencyIsAccepted(address(eth), 3),
            false
        );
    }

    function testCreateGalleryThree() public {
        createInitialGalleryAndCollections();

        uint256[] memory collsExpected = new uint256[](4);
        collsExpected[0] = 1;
        collsExpected[1] = 2;
        collsExpected[2] = 3;
        collsExpected[3] = 4;

        assertEq(autographData.getGalleryCollectionCount(1), 4);
        assertEq(autographData.getGalleryCollections(1), collsExpected);
        assertEq(autographData.getCollectionGallery(1), 1);
        assertEq(autographData.getCollectionGallery(3), 1);
        assertEq(
            autographData.getArtistCollectionsAvailable(designer),
            collsExpected
        );
        assertEq(autographData.getMintedTokenIdsByGalleryId(1, 1).length, 0);
    }

    function testAddPubProfileCollection() public {
        createInitialGalleryAndCollections();

        AutographLibrary.OpenActionParams memory params = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.NFT,
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

        assertEq(autographData.getGalleryByPublication(900, 450), 1);
        assertEq(autographData.getGalleryByPublication(900, 1543), 1);
        assertEq(autographData.getCollectionByPublication(900, 450), 1);
        assertEq(autographData.getCollectionByPublication(900, 1543), 4);
        assertEq(
            autographData.getCollectionProfileIdsByGalleryId(1, 1)[0],
            900
        );
        assertEq(
            autographData.getCollectionProfileIdsByGalleryId(4, 1)[0],
            900
        );
        assertEq(autographData.getCollectionPubIdsByGalleryId(1, 1)[0], 450);
        assertEq(autographData.getCollectionPubIdsByGalleryId(4, 1)[0], 1543);
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

        createInitialGalleryAndCollections();

        colls = autographData.getGalleryCollections(2);
        assertEq(colls.length, 4);
    }

    function testCatalogPurchaseOpenAction() public {
        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(matic);
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

        Types.ProcessActionParams memory process = Types.ProcessActionParams({
            actorProfileOwner: buyer,
            actorProfileId: 43,
            actionModuleData: abi.encode(
                "encryptedForCatalog",
                address(eth),
                2,
                AutographLibrary.AutographType.Catalog
            ),
            publicationActedProfileId: 900,
            publicationActedId: 120,
            transactionExecutor: buyer,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referrerPubTypes: new Types.PublicationType[](0)
        });

        eth.transfer(buyer, 96270018146898420);
        vm.startPrank(buyer);
        eth.approve(address(autographMarket), 96270018146898420);

        vm.startPrank(hub);
        autographOpenAction.processPublicationAction(process);

        assertEq(autographData.getOrderCounter(), 1);
        assertEq(autographData.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographData.getOrderTotal(1), 200000000000000000000);
        assertEq(autographData.getOrderFulfillment(1), "encryptedForCatalog");
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTypes(1)))),
            keccak256(
                abi.encodePacked(([AutographLibrary.AutographType.Catalog]))
            )
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderAmounts(1)))),
            keccak256(abi.encodePacked(([2])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTotals(1)))),
            keccak256(abi.encodePacked(([200000000000000000000])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderParentIds(1)))),
            keccak256(abi.encodePacked(([0])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[0]))
            ),
            keccak256(abi.encodePacked(([0])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderCurrencies(1)))),
            keccak256(abi.encodePacked(([address(eth)])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[0]))
            ),
            keccak256(abi.encodePacked(([1, 2])))
        );
    }

    function testCollectionNFTPurchaseOpenAction() public {
        createInitialGalleryAndCollections();
        AutographLibrary.OpenActionParams memory params = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.NFT,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 3,
                galleryId: 1
            });

        bytes memory data = abi.encode(params);

        vm.prank(hub);
        autographOpenAction.initializePublicationAction(
            900,
            532,
            designer,
            data
        );

        params = AutographLibrary.OpenActionParams({
            autographType: AutographLibrary.AutographType.NFT,
            price: 0,
            acceptedTokens: new address[](0),
            uri: "",
            amount: 0,
            pages: new string[](0),
            pageCount: 0,
            collectionId: 2,
            galleryId: 1
        });

        data = abi.encode(params);
        vm.prank(hub);
        autographOpenAction.initializePublicationAction(
            900,
            600,
            designer,
            data
        );

        matic.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        matic.approve(address(autographMarket), 259000259000259000259);

        Types.ProcessActionParams memory process = Types.ProcessActionParams({
            actorProfileOwner: buyer,
            actorProfileId: 43,
            actionModuleData: abi.encode(
                "encryptedForCollectionNFT",
                address(matic),
                1,
                AutographLibrary.AutographType.NFT
            ),
            publicationActedProfileId: 900,
            publicationActedId: 532,
            transactionExecutor: buyer,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referrerPubTypes: new Types.PublicationType[](0)
        });

        vm.prank(hub);
        autographOpenAction.processPublicationAction(process);

        assertEq(autographData.getOrderCounter(), 1);
        assertEq(autographData.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographData.getOrderTotal(1), 200000000000000000000);
        assertEq(
            autographData.getOrderFulfillment(1),
            "encryptedForCollectionNFT"
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTypes(1)))),
            keccak256(abi.encodePacked(([AutographLibrary.AutographType.NFT])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderAmounts(1)))),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTotals(1)))),
            keccak256(abi.encodePacked(([200000000000000000000])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderParentIds(1)))),
            keccak256(abi.encodePacked(([0])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[0]))
            ),
            keccak256(abi.encodePacked(([3])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderCurrencies(1)))),
            keccak256(abi.encodePacked(([address(matic)])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[0]))
            ),
            keccak256(abi.encodePacked(([1])))
        );

        usdt.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 259000259000259000259);

        process = Types.ProcessActionParams({
            actorProfileOwner: buyer,
            actorProfileId: 43,
            actionModuleData: abi.encode(
                "encryptedForCollectionNFT",
                address(usdt),
                2,
                AutographLibrary.AutographType.NFT
            ),
            publicationActedProfileId: 900,
            publicationActedId: 600,
            transactionExecutor: buyer,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referrerPubTypes: new Types.PublicationType[](0)
        });

        vm.prank(hub);
        try autographOpenAction.processPublicationAction(process) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXCEED_AMOUNT_ERROR));
        }

        process = Types.ProcessActionParams({
            actorProfileOwner: buyer,
            actorProfileId: 43,
            actionModuleData: abi.encode(
                "encryptedForCollectionNFT",
                address(usdt),
                1,
                AutographLibrary.AutographType.NFT
            ),
            publicationActedProfileId: 900,
            publicationActedId: 600,
            transactionExecutor: buyer,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referrerPubTypes: new Types.PublicationType[](0)
        });
        vm.startPrank(hub);
        autographOpenAction.processPublicationAction(process);

        assertEq(
            keccak256(
                abi.encodePacked(
                    (autographData.getArtistCollectionsAvailable(designer))
                )
            ),
            keccak256(abi.encodePacked(([1, 4, 3])))
        );

        try autographOpenAction.processPublicationAction(process) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXCEED_AMOUNT_ERROR));
        }
    }

    function testCollectionPrintPurchaseOpenAction() public {
        createInitialGalleryAndCollections();

        usdt.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 259000259000259000259);

        AutographLibrary.OpenActionParams memory params = AutographLibrary
            .OpenActionParams({
                autographType: AutographLibrary.AutographType.Hoodie,
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
            123333,
            designer,
            data
        );

        Types.ProcessActionParams memory process = Types.ProcessActionParams({
            actorProfileOwner: buyer,
            actorProfileId: 103,
            actionModuleData: abi.encode(
                "encryptedForCollectionHoodie",
                address(usdt),
                1,
                AutographLibrary.AutographType.Hoodie
            ),
            publicationActedProfileId: 900,
            publicationActedId: 123333,
            transactionExecutor: buyer,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            referrerPubTypes: new Types.PublicationType[](0)
        });
        vm.startPrank(hub);
        autographOpenAction.processPublicationAction(process);

        assertEq(
            keccak256(
                abi.encodePacked(
                    (autographData.getArtistCollectionsAvailable(designer))
                )
            ),
            keccak256(abi.encodePacked(([1, 2, 3, 4])))
        );
    }

    function testCatalogCollectionPurchase() public {
        createInitialGalleryAndCollections();

        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(mona);
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

        eth.transfer(buyer, 298810054000000000);
        vm.prank(buyer);
        eth.approve(address(autographMarket), 298810054000000000);

        mona.transfer(buyer, 972880234000000000);
        vm.prank(buyer);
        mona.approve(address(autographMarket), 972880234000000000);

        address[] memory currencies = new address[](2);
        currencies[0] = address(mona);
        currencies[1] = address(eth);
        uint256[][] memory collectionIds = new uint256[][](2);
        collectionIds[0] = new uint256[](1);
        collectionIds[0][0] = 0;
        collectionIds[1] = new uint256[](1);
        collectionIds[1][0] = 4;

        uint256[] memory maxAmount = new uint256[](2);
        maxAmount[0] = 0;
        maxAmount[1] = 0;
        uint8[] memory quantities = new uint8[](2);
        quantities[0] = 4;
        quantities[1] = 2;
        AutographLibrary.AutographType[]
            memory types = new AutographLibrary.AutographType[](2);
        types[0] = AutographLibrary.AutographType.Catalog;
        types[1] = AutographLibrary.AutographType.Shirt;
        uint256 designerBalanceEth = eth.balanceOf(designer);
        uint256 buyerBalanceEth = eth.balanceOf(buyer);
        uint256 designerBalanceMona = mona.balanceOf(owner);
        uint256 buyerBalanceMona = mona.balanceOf(buyer);
        vm.prank(buyer);
        autographMarket.buyTokens(
            collectionIds,
            currencies,
            maxAmount,
            quantities,
            types,
            "fulfillment here"
        );

        assertEq(
            eth.balanceOf(designer),
            designerBalanceEth + 228641293098883749
        );
        assertEq(eth.balanceOf(fulfiller), 60168761341811512);
        assertEq(
            mona.balanceOf(owner),
            designerBalanceMona + 972880233822035396
        );
        assertEq(eth.balanceOf(buyer), buyerBalanceEth - 288810054440695261);
        assertEq(mona.balanceOf(buyer), buyerBalanceMona - 972880233822035396);
        assertEq(autographData.getAutographMinted(), 4);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[1]))
            ),
            keccak256(abi.encodePacked(([4])))
        );
    }

    function testMixPurchase() public {
        createInitialGalleryAndCollections();

        address[] memory currencies = new address[](1);
        currencies[0] = address(usdt);
        uint256[][] memory collectionIds = new uint256[][](1);
        collectionIds[0] = new uint256[](1);
        uint256[] memory maxAmount = new uint256[](1);
        maxAmount[0] = 1000000000000000000000;
        uint8[] memory quantities = new uint8[](1);
        quantities[0] = 1;
        AutographLibrary.AutographType[]
            memory types = new AutographLibrary.AutographType[](1);
        types[0] = AutographLibrary.AutographType.Mix;

        usdt.transfer(buyer, 1000000000000000000000);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 1000000000000000000000);
        uint256 designerBalanceUsdt = usdt.balanceOf(designer);
        uint256 buyerBalanceUsdt = usdt.balanceOf(buyer);
        vm.prank(buyer);
        autographMarket.buyTokens(
            collectionIds,
            currencies,
            maxAmount,
            quantities,
            types,
            "fulfillment here"
        );

        assertEq(autographData.getOrderCounter(), 1);
        assertEq(autographData.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographData.getOrderTotal(1), 600000000000000000000);
        assertEq(autographData.getOrderFulfillment(1), "fulfillment here");
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTypes(1)))),
            keccak256(abi.encodePacked(([AutographLibrary.AutographType.Mix])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderAmounts(1)))),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTotals(1)))),
            keccak256(abi.encodePacked(([600000000000000000000])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderParentIds(1)))),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[0]))
            ),
            keccak256(abi.encodePacked(([3, 4, 1])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderCurrencies(1)))),
            keccak256(abi.encodePacked(([address(usdt)])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[0]))
            ),
            keccak256(abi.encodePacked(([2, 3, 4])))
        );
        assertEq(usdt.balanceOf(buyer), buyerBalanceUsdt - 600000000);
        assertEq(
            usdt.balanceOf(designer),
            designerBalanceUsdt + (600000000 - 110000000 - 14500000)
        );
    }

    function testAllPurchase() public {
        createInitialGalleryAndCollections();

        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(mona);
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

        address[] memory currencies = new address[](6);
        currencies[0] = address(mona);
        currencies[1] = address(usdt);
        currencies[2] = address(eth);
        currencies[3] = address(mona);
        currencies[4] = address(eth);
        currencies[5] = address(usdt);
        uint256[][] memory collectionIds = new uint256[][](6);
        collectionIds[0] = new uint256[](1);
        collectionIds[1] = new uint256[](1);
        collectionIds[2] = new uint256[](1);
        collectionIds[2][0] = 2;
        collectionIds[3] = new uint256[](1);
        collectionIds[3][0] = 1;
        collectionIds[4] = new uint256[](1);
        collectionIds[4][0] = 4;
        collectionIds[5] = new uint256[](1);
        uint256[] memory maxAmount = new uint256[](6);
        maxAmount[0] = 0;
        maxAmount[1] = 1000000000000000000000;
        maxAmount[2] = 0;
        maxAmount[3] = 0;
        maxAmount[4] = 0;
        maxAmount[5] = 1000000000000000000000;
        uint8[] memory quantities = new uint8[](6);
        quantities[0] = 3;
        quantities[1] = 1;
        quantities[2] = 1;
        quantities[3] = 3;
        quantities[4] = 4;
        quantities[5] = 1;
        AutographLibrary.AutographType[]
            memory types = new AutographLibrary.AutographType[](6);
        types[0] = AutographLibrary.AutographType.Catalog;
        types[1] = AutographLibrary.AutographType.Mix;
        types[2] = AutographLibrary.AutographType.NFT;
        types[3] = AutographLibrary.AutographType.Hoodie;
        types[4] = AutographLibrary.AutographType.Shirt;
        types[5] = AutographLibrary.AutographType.Mix;

        usdt.transfer(buyer, 1200000000);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 1200000000);

        eth.transfer(buyer, 673890127028288944);
        vm.prank(buyer);
        eth.approve(address(autographMarket), 673890127028288944);

        mona.transfer(buyer, 1459320350733053095);
        vm.prank(buyer);
        mona.approve(address(autographMarket), 1459320350733053095);

        uint256 designerBalanceUsdt = usdt.balanceOf(designer);
        uint256 buyerBalanceUsdt = usdt.balanceOf(buyer);
        uint256 designerBalanceEth = eth.balanceOf(designer);
        uint256 buyerBalanceEth = eth.balanceOf(buyer);
        uint256 designerBalanceMona = mona.balanceOf(designer);
        uint256 buyerBalanceMona = mona.balanceOf(buyer);
        uint256 ownerBalanceMona = mona.balanceOf(owner);

        vm.prank(buyer);
        autographMarket.buyTokens(
            collectionIds,
            currencies,
            maxAmount,
            quantities,
            types,
            "fulfillment here"
        );

        assertEq(autographData.getOrderCounter(), 1);
        assertEq(autographData.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographData.getOrderTotal(1), 3180000000000000000000);
        assertEq(autographData.getOrderFulfillment(1), "fulfillment here");
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTypes(1)))),
            keccak256(
                abi.encodePacked(
                    (
                        [
                            AutographLibrary.AutographType.Catalog,
                            AutographLibrary.AutographType.Mix,
                            AutographLibrary.AutographType.NFT,
                            AutographLibrary.AutographType.Hoodie,
                            AutographLibrary.AutographType.Shirt,
                            AutographLibrary.AutographType.Mix
                        ]
                    )
                )
            )
        );

        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderAmounts(1)))),
            keccak256(abi.encodePacked(([3, 1, 1, 3, 4, 1])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderSubTotals(1)))),
            keccak256(
                abi.encodePacked(
                    (
                        [
                            300000000000000000000,
                            600000000000000000000,
                            180000000000000000000,
                            300000000000000000000,
                            1200000000000000000000,
                            600000000000000000000
                        ]
                    )
                )
            )
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderParentIds(1)))),
            keccak256(abi.encodePacked(([0, 1, 0, 0, 0, 13])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[0]))
            ),
            keccak256(abi.encodePacked(([0])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[1]))
            ),
            keccak256(abi.encodePacked(([3, 4, 1])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[2]))
            ),
            keccak256(abi.encodePacked(([2])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[3]))
            ),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[4]))
            ),
            keccak256(abi.encodePacked(([4])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderCollectionIds(1)[5]))
            ),
            keccak256(abi.encodePacked(([3, 4, 1])))
        );
        assertEq(
            keccak256(abi.encodePacked((autographData.getOrderCurrencies(1)))),
            keccak256(
                abi.encodePacked(
                    (
                        [
                            address(mona),
                            address(usdt),
                            address(eth),
                            address(mona),
                            address(eth),
                            address(usdt)
                        ]
                    )
                )
            )
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[0]))
            ),
            keccak256(abi.encodePacked(([1, 2, 3])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[1]))
            ),
            keccak256(abi.encodePacked(([2, 3, 4])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[2]))
            ),
            keccak256(abi.encodePacked(([5])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[3]))
            ),
            keccak256(abi.encodePacked(([6, 7, 8])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[4]))
            ),
            keccak256(abi.encodePacked(([9, 10, 11, 12])))
        );
        assertEq(
            keccak256(
                abi.encodePacked((autographData.getOrderMintedTokens(1)[5]))
            ),
            keccak256(abi.encodePacked(([14, 15, 16])))
        );
        assertEq(usdt.balanceOf(buyer), buyerBalanceUsdt - 1200000000);
        assertEq(
            usdt.balanceOf(designer),
            designerBalanceUsdt +
                (1200000000 - 110000000 - 14500000 - 110000000 - 14500000)
        );
        assertEq(mona.balanceOf(buyer), buyerBalanceMona - 1459320350733053094);
        assertEq(
            mona.balanceOf(designer),
            designerBalanceMona + 277270866639280088
        );
        assertEq(mona.balanceOf(owner), ownerBalanceMona + 729660175366526547);
        assertEq(
            eth.balanceOf(buyer),
            buyerBalanceEth - 664263125213599101
        );
        assertEq(
            eth.balanceOf(designer),
            designerBalanceEth + 543925602529976076
        );
    }

    function moveAndBurnParentAndChild() public {
        
    }
}
