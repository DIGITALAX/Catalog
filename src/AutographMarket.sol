// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";

contract AutographMarket {
    AutographAccessControl public autographAccessControl;
    string public symbol;
    string public name;

    error InvalidAddress();

    modifier onlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl
    ) {
        symbol = _symbol;
        name = _name;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function buyTokens() external onlyOpenAction {}

    function createOrder() internal {}
}
