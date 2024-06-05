// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographData.sol";

contract AutographNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    uint256 private _supply;

    error AddressNotVerified();

    event BatchTokenMinted(address purchaser, uint256[] tokenIds);

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
        address _autographAccessControlAddress,
        address _autographDataAddress
    ) ERC721("AutographNFT", "CNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
        autographData = AutographData(_autographDataAddress);
    }

    function mintBatch(
        address _purchaserAddress,
        uint256 _amount
    ) public OnlyOpenAction {
        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            _supply++;
            _safeMint(_purchaserAddress, _supply);
        }

        emit BatchTokenMinted(_purchaserAddress, tokenIds);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return autographData.getAutographURIById(0);
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }
}
