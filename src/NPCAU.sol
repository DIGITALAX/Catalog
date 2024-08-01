// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NPCAU is ERC20 {
    address public manualNFT;

    constructor(address _npcModule) ERC20("Autonomy Units", "AU") {
        manualNFT = _npcModule;
    }

    error InvalidAddress();

    modifier OnlyManual() {
        if (msg.sender != manualNFT) {
            revert InvalidAddress();
        }
        _;
    }

    function mint(address _to, uint256 _amount) public OnlyManual {
        _mint(_to, _amount);
    }
}
