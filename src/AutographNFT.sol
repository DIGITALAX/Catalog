// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographData.sol";

contract AutographNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    address public autographMarket;
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

    modifier OnlyMarket() {
        if (msg.sender != autographMarket) {
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
        address _purchaserAddress,
        uint8 _amount
    ) public OnlyMarket returns(uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint8 i = 0; i < _amount; i++) {
            _supply++;
            _safeMint(_purchaserAddress, _supply);
            tokenIds[i]= _supply;
        }

        autographData.setMintedCatalog(_amount);

        emit BatchTokenMinted(_purchaserAddress, tokenIds);

        return tokenIds;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return autographData.getAutographURI();
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }

    function setAutographData(address _autographData) public OnlyAdmin {
        autographData = AutographData(_autographData);
    }

    function setAutographMarketAddress(
        address _autographMarketAddress
    ) public OnlyAdmin {
        autographMarket = _autographMarketAddress;
    }
}
