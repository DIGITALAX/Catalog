// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract AutographLibrary {
    enum AutographType {
        CollectionNFT,
        CollectionHoodie,
        CollectionShirt,
        Catalog,
        Mix
    }

    enum CollectionType {
        Print,
        Digital
    }

    struct OpenActionParams {
        address[] acceptedTokens;
        string uri;
        AutographType autographType;
        uint256 collectionId;
        uint256 amount;
        uint256 price;
        uint16 galleryId;
    }

    struct AutographInit {
        address[] acceptedTokens;
        string uri;
        address designer;
        uint256 amount;
        uint256 price;
        uint256 pubId;
        uint256 profileId;
    }

    struct Autograph {
        address[] acceptedTokens;
        string uri;
        address designer;
        uint256 amount;
        uint256 price;
        uint256 id;
        uint256 pubId;
        uint256 profileId;
    }

    struct CollectionInit {
        address[][] acceptedTokens;
        uint256[] prices;
        string[] uris;
        uint256[] amounts;
        CollectionType[] collectionTypes;
    }

    struct Collection {
        address[] acceptedTokens;
        uint256[] pubIds;
        uint256[] profileIds;
        uint256[] mintedTokenIds;
        string uri;
        address designer;
        uint256 price;
        uint256 amount;
        uint256 galleryId;
        uint256 collectionId;
        CollectionType collectionType;
    }

    struct CollectionMap {
        uint256 collectionId;
        uint16 galleryId;
    }
}
