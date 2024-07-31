// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NPCAU is ERC20 {
    constructor() ERC20("Autonomy Units", "AU") {}
    
}
