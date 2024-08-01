// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AutographAccessControl.sol";

contract ManualNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    address public npcControls;
    uint256 private _supply;
    IERC20 public auToken;
    address public npcRent;

    error AddressNotVerified();
    error InsufficientTokenBalance();
    error IncorrectBalance();

    event TokenMinted(address creator, uint256 tokenId, uint256 auAmount);
    event TokensRemoved(uint256 tokenId, uint256 amount, address recipient);

    mapping(uint256 => string) private _tokenToURI;
    mapping(uint256 => uint256) public tokenAUBalance;

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

    modifier OnlynpcRent() {
        if (msg.sender != npcRent) {
            revert AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress,
        address _npcControls,
        address _auTokenAddress,
        address _npcRent
    ) ERC721("Manual NFT", "MNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
        npcControls = _npcControls;
        auToken = IERC20(_auTokenAddress);
        npcRent = _npcRent;
    }

    function mint(
        string memory _uri,
        address _creatorAddress,
        uint256 _auAmount,
        bool _live
    ) public OnlyControls returns (uint256) {
        _supply++;
        _safeMint(_creatorAddress, _supply);

        _tokenToURI[_supply] = _uri;
        tokenAUBalance[_supply] = _auAmount;

        if (_live) {
            require(
                auToken.transferFrom(msg.sender, address(this), _auAmount),
                "AU transfer failed"
            );
        }

        emit TokenMinted(_creatorAddress, _supply, _auAmount);

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

    function removeTokens(
        uint256 _tokenId,
        uint256 _amount,
        address _recipient
    ) public OnlynpcRent {
        if (_amount > tokenAUBalance[_tokenId]) {
            revert IncorrectBalance();
        }

        tokenAUBalance[_tokenId] -= _amount;
        require(auToken.transfer(_recipient, _amount), "AU transfer failed");
        emit TokensRemoved(_tokenId, _amount, _recipient);
    }

    function getAUBalance(uint256 _tokenId) public view returns (uint256) {
        return tokenAUBalance[_tokenId];
    }

    function setNPCRent(address _npcRent) public OnlyAdmin {
        npcRent = _npcRent;
    }
}
