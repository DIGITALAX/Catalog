// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";

contract AutographNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    uint256 private _tokenIds;

    error AddressNotVerified();

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    modifier OnlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress
    ) ERC721("AutographNFT", "CNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
    }

   
    function mintBatch(
        string memory _uri,
        address _purchaserAddress,
        address _chosenCurrency,
        uint256 _amount
    ) public OnlyOpenAction {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 _supply = autographData.getAutographSupply();
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
