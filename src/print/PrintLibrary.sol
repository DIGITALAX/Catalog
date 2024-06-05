// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.16;

contract PrintLibrary {
    enum OrderStatus {
        Fulfilled,
        Shipped,
        Shipping,
        Designing
    }

    struct Collection {
        address[] acceptedTokens;
        uint256[] prices;
        uint256[] tokenIds;
        uint256[] communityIds;
        string uri;
        address fulfiller;
        address creator;
        uint256 collectionId;
        uint256 pubId;
        uint256 profileId;
        uint256 dropId;
        uint256 mintedTokens;
        uint256 amount;
        uint256 origin;
        uint256 printType;
        bool unlimited;
        bool encrypted;
    }

    struct Drop {
        uint256[] collectionIds;
        string uri;
        address creator;
        uint256 dropId;
    }
    struct Token {
        string uri;
        address chosenCurrency;
        uint256 tokenId;
        uint256 collectionId;
        uint256 index;
    }
    struct Order {
        uint256[] subOrderIds;
        string[] messages;
        string details;
        address buyer;
        address chosenCurrency;
        uint256 orderId;
        uint256 pubId;
        uint256 profileId;
        uint256 buyerProfileId;
        uint256 timestamp;
        uint256 totalPrice;
        bool withPKP;
    }
    struct NFTOnlyOrder {
        string[] messages;
        uint256[] tokenIds;
        address buyer;
        address chosenCurrency;
        uint256 orderId;
        uint256 pubId;
        uint256 profileId;
        uint256 buyerProfileId;
        uint256 timestamp;
        uint256 totalPrice;
        uint256 collectionId;
        uint256 amount;
    }
    struct Community {
        address[] validCreatorKeys;
        address[] valid20AddressKeys;
        uint256[] validOriginKeys;
        uint256[] validPrintTypeKeys;
        mapping(address => bool) validCreators;
        mapping(uint256 => bool) validOrigins;
        mapping(uint256 => bool) validPrintTypes;
        mapping(address => uint256) valid20Thresholds;
        CommunityMember[] communityMembers;
        string uri;
        address steward;
        uint256 communityId;
    }
    struct CommunityMember {
        address memberAddress;
        uint256 memberProfileId;
    }

    struct SubOrder {
        uint256[] tokenIds;
        address fulfiller;
        uint256 subOrderId;
        uint256 collectionId;
        uint256 orderId;
        uint256 amount;
        uint256 price;
        PrintLibrary.OrderStatus status;
        bool isFulfilled;
    }
    struct MintParams {
        address[] acceptedTokens;
        uint256[] prices;
        uint256[] communityIds;
        string uri;
        address fulfiller;
        address creator;
        uint256 printType;
        uint256 origin;
        uint256 amount;
        uint256 pubId;
        uint256 profileId;
        uint256 dropId;
        bool unlimited;
        bool encrypted;
    }
    struct CreateCommunityParams {
        address[] validCreators;
        uint256[] validOrigins;
        uint256[] validPrintTypes;
        address[] valid20Addresses;
        uint256[] valid20Thresholds;
        string uri;
        address steward;
    }
    struct BuyTokensParams {
        uint256[] collectionIds;
        uint256[] collectionAmounts;
        uint256[] collectionIndexes;
        string details;
        address buyerAddress;
        address chosenCurrency;
        address pkpAddress;
        uint256 pubId;
        uint256 profileId;
        uint256 buyerProfileId;
        bool withPKP;
    }
    struct BuyTokensOnlyNFTParams {
        uint256 collectionId;
        uint256 quantity;
        address buyerAddress;
        address chosenCurrency;
        uint256 pubId;
        uint256 profileId;
        uint256 buyerProfileId;
    }

    struct CollectionValuesParams {
        uint256[] prices;
        uint256[] communityIds;
        address[] acceptedTokens;
        string uri;
        address fulfiller;
        uint256 amount;
        uint256 dropId;
        bool unlimited;
        bool encrypted;
    }
}
