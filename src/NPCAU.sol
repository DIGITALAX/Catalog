// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NPCAU is ERC20 {
    address public npcModule;

    constructor(address _npcModule) ERC20("Autonomy Units", "AU") {
        npcModule = _npcModule;
    }

    error InvalidAddress();

    modifier OnlyModule() {
        if (msg.sender != npcModule) {
            revert InvalidAddress();
        }
        _;
    }

    function mint(uint256 _amount) public OnlyModule {}

    function mintAdditionalAU(uint256 _amount) public OnlyModule {}
}
