// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract AutographLibrary {
    enum AutographType {
        CollectionNFT,
        CollectionPrint,
        Catalog,
        Mix
    }

    enum CollectionType {
        Print,
        Digital
    }

    struct OpenActionParams {
        address[][] acceptedTokens;
        uint256[][] prices;
        string[] uris;
        uint256[] amounts;
        uint256[] pubIds;
        uint256[] profileIds;
        CollectionType[] collectionTypes;
        AutographType autographType;
    }

    struct AutographInit {
        address[] acceptedTokens;
        uint256[] prices;
        string uri;
        uint256 amount;
        uint256 pubId;
        uint256 profileId;
    }

    struct Autograph {
        address[] acceptedTokens;
        uint256[] prices;
        string uri;
        uint256 amount;
        uint256 id;
        uint256 pubId;
        uint256 profileId;
    }

    struct CollectionInit {
        address[][] acceptedTokens;
        uint256[][] prices;
        string[] uris;
        uint256[] amounts;
        uint256[] pubIds;
        uint256[] profileIds;
        CollectionType[] collectionTypes;
    }

    struct Collection {
        address[] acceptedTokens;
        uint256[] prices;
        string uri;
        uint256 amount;
        uint256 pubId;
        uint256 profileId;
        uint256 id;
        CollectionType collectionType;
    }
}
