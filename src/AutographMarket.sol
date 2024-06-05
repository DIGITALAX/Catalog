// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographData.sol";

contract AutographMarket {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    string public symbol;
    string public name;

    error InvalidAddress();

    modifier OnlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl,
        address _autographData
    ) {
        symbol = _symbol;
        name = _name;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographData = AutographData(_autographData);
    }

    function buyTokens(
        address[] memory _currencies,
        uint256[] memory _collectionIds,
        uint8[] memory _quantities,
        uint8[] memory _chosenIndexes,
        AutographLibrary.AutographType[] memory _types,
        string memory _encryptedFulfillment,
        address _buyer
    ) external {}

    function createOrder() internal {}
}
