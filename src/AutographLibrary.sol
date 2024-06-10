// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract AutographLibrary {
    enum AutographType {
        NFT,
        Hoodie,
        Shirt,
        Catalog,
        Mix
    }

    enum LensType {
        Catalog,
        Comment,
        Publication,
        Autograph
    }

    struct Publication {
        address artist;
        address npc;
        LensType lensType;
    }

    struct OpenActionParams {
        string[] pages;
        address[] acceptedTokens;
        string uri;
        AutographType autographType;
        uint256 collectionId;
        uint256 price;
        uint16 galleryId;
        uint16 amount;
        uint8 pageCount;
    }

    struct AutographInit {
        string[] pages;
        address[] acceptedTokens;
        string uri;
        address designer;
        uint256 price;
        uint256 pubId;
        uint256 profileId;
        uint16 amount;
        uint8 pageCount;
    }

    struct Autograph {
        string[] pages;
        address[] acceptedTokens;
        string uri;
        address designer;
        uint256 price;
        uint256 id;
        uint256 pubId;
        uint256 profileId;
        uint16 amount;
        uint16 minted;
        uint8 pageCount;
    }

    struct CollectionInit {
        address[][] acceptedTokens;
        uint256[] prices;
        string[] uris;
        uint8[] amounts;
        AutographType[] collectionTypes;
    }

    struct Collection {
        address[] acceptedTokens;
        uint256[] pubIds;
        uint256[] profileIds;
        uint256[] mintedTokenIds;
        string uri;
        address designer;
        uint256 price;
        uint256 galleryId;
        uint256 collectionId;
        uint8 amount;
        AutographType collectionType;
    }

    struct CollectionMap {
        uint256 collectionId;
        uint16 galleryId;
    }

    struct Order {
        uint256[][] mintedTokenIds;
        uint256[][] collectionIds;
        address[] currencies;
        uint256[] parentIds;
        uint256[] subTotals;
        uint8[] amounts;
        AutographType[] subOrderTypes;
        string fulfillment;
        address buyer;
        uint256 orderId;
        uint256 total;
    }

    struct NonMixParams {
        address[] currencies;
        uint256[] collectionIds;
        uint8[] quantities;
        AutographType[] types;
        address buyer;
        uint256 index;
    }

    struct Transfer {
        address buyer;
        address fulfiller;
        address designer;
        address chosenCurrency;
        uint256 designerAmount;
        uint256 fulfillerAmount;
    }

    struct Split {
        uint256 collectionId;
        uint16 galleryId;
        uint8 chosenAmount;
        AutographLibrary.AutographType autographType;
    }

    struct TransferType {
        address buyer;
        uint256 collectionId;
        uint16 galleryId;
        uint8 chosenAmount;
        AutographLibrary.AutographType autographType;
    }

    struct NonMixTransfer {
        address chosenCurrency;
        address buyer;
        uint256 collectionId;
        uint8 chosenAmount;
        uint16 galleryId;
        AutographLibrary.AutographType autographType;
    }
}
