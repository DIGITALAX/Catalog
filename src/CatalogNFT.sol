// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./CatalogAccessControl.sol";

contract CatalogNFT is ERC721Enumerable {
    CatalogAccessControl public catalogAccessControl;
    uint256 private _tokenIds;

    error AddressNotVerified();

    modifier OnlyAdmin() {
        if (!catalogAccessControl.isAdmin(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    modifier OnlyOpenAction() {
        if (!catalogAccessControl.isOpenAction(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }



    constructor(
        address _catalogAccessControlAddress
    ) ERC721("CatalogNFT", "CNFT") {
        catalogAccessControl = CatalogAccessControl(
            _catalogAccessControlAddress
        );
    }

   
    function mintBatch(
        string memory _uri,
        address _purchaserAddress,
        address _chosenCurrency,
        uint256 _amount,
        uint256 _collectionId,
        uint256 _chosenIndex
    ) public OnlyOpenAction {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 _supply = catalogData.getCatalogSupply();
        for (uint256 i = 0; i < _amount; i++) {
            PrintLibrary.Token memory newToken = PrintLibrary.Token({
                uri: _uri,
                chosenCurrency: _chosenCurrency,
                tokenId: _supply + i + 1,
                collectionId: _collectionId,
                index: _chosenIndex
            });
            _safeMint(_purchaserAddress, _supply + i + 1);
            printData.setNFT(newToken);
            tokenIds[i] = _supply + i + 1;
        }

        emit BatchTokenMinted(_purchaserAddress, tokenIds);
    }
}
