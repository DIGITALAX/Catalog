// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";

contract AUNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    address public npcControls;
    uint256 private _supply;

    error AddressNotVerified();
    event TokenMinted(address creator, uint256 tokenId);

    mapping(uint256 => string) private _tokenToURI;

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    modifier OnlyControls() {
        if (msg.sender != npcControls) {
            revert AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress,
        address _npcControls
    ) ERC721("Autonomous Units NFT", "AUNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
        npcControls = _npcControls;
    }

    function mint(
        string memory _uri,
        address _creatorAddress
    ) public OnlyControls returns (uint256) {
        _supply++;
        _safeMint(_creatorAddress, _supply);

        _tokenToURI[_supply] = _uri;

        emit TokenMinted(_creatorAddress, _supply);

        return _supply;
    }

    function setMetadata(
        string memory _uri,
        uint256 _tokenId
    ) public OnlyControls {
        _tokenToURI[_tokenId] = _uri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return _tokenToURI[_tokenId];
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }
}
