// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./NPCAU.sol";
import "./NPCControls.sol";

contract ManualNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    NPCControls public npcControls;
    uint256 private _supply;
    NPCAU public auToken;
    address public npcRent;

    error AddressNotVerified();
    error InsufficientTokenBalance();
    error IncorrectBalance();
    error AddressNotNPC();
    error ModulePaused();

    event TokenMinted(address creator, uint256 tokenId, uint256 auAmount);
    event RentPaid(address npc, uint256 tokenId, uint256 amount);
    event SpectatedAU(address npc, uint256 tokenId, uint256 amount);

    mapping(uint256 => string) private _tokenToURI;
    mapping(uint256 => uint256) public tokenAUBalance;

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    modifier OnlyNPC() {
        if (!autographAccessControl.isNPC(msg.sender)) {
            revert AddressNotNPC();
        }
        _;
    }

    modifier OnlyControls() {
        if (msg.sender != address(npcControls)) {
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
        npcControls = NPCControls(_npcControls);
        auToken = NPCAU(_auTokenAddress);
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

        if (_live) {
            auToken.mint(address(this), _auAmount);
        }

        _tokenToURI[_supply] = _uri;
        tokenAUBalance[_supply] = _auAmount;

        emit TokenMinted(_creatorAddress, _supply, _auAmount);

        return _supply;
    }

    function chargeSpectatedAU(
        address _creatorAddress,
        uint256 _auAmount
    ) external OnlyControls {
        auToken.mint(address(this), _auAmount);
        tokenAUBalance[_supply] = tokenAUBalance[_supply] + _auAmount;

        emit SpectatedAU(_creatorAddress, _supply, _auAmount);
    }

    function npcTransferAU(
        address _creator,
        uint256 _moduleId,
        uint256 _tokenId,
        uint256 _amount
    ) public OnlyNPC {
        if (_amount > tokenAUBalance[_tokenId]) {
            revert IncorrectBalance();
        }
        if (!npcControls.getNPCModuleLive(msg.sender, _creator, _moduleId)) {
            revert ModulePaused();
        }

        auToken.approve(msg.sender, _amount);
        auToken.transferFrom(address(this), npcRent, _amount);
        tokenAUBalance[_tokenId] -= _amount;

        emit RentPaid(msg.sender, _tokenId, _amount);
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

    function getAUBalance(uint256 _tokenId) public view returns (uint256) {
        return tokenAUBalance[_tokenId];
    }

    function setNPCRent(address _npcRent) public OnlyAdmin {
        npcRent = _npcRent;
    }
}
