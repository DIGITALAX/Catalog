// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract CatalogLibrary {

      enum CatalogType {
        Collection,
        Print
    }
   
 struct CatalogInitParams {
        address[] acceptedTokens;
        uint256[] prices;
        string uri;
        address creator;
        uint256 amount;
        uint256 dropId;
        CatalogType catalogType;
    }

struct Catalog {
    address[] acceptedTokens;
    uint256[] prices;
    string uri;
    uint256 amount;
    uint256 id;
}


}
