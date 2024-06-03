// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.23;

contract CatalogAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _designers;
    mapping(address => bool) private _openActions;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event DesignerAdded(address indexed designer);
    event DesignerRemoved(address indexed designer);
    event OpenActionAdded(address indexed openAction);
    event OpenActionRemoved(address indexed openAction);

    error AddressInvalid();
    error Existing();
    error CantRemoveSelf();

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert AddressInvalid();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "CAC";
        name = "CatalogAccessControl";
    }

    function addAdmin(address _admin) external onlyAdmin {
        if (_admins[_admin] || _admin == msg.sender) {
            revert Existing();
        }
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == msg.sender) {
            revert CantRemoveSelf();
        }
        if (!_admins[_admin]) {
            revert AddressInvalid();
        }
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function addDesigner(address _designer) external onlyAdmin {
        if (_designers[_designer]) {
            revert Existing();
        }
        _designers[_designer] = true;
        emit DesignerAdded(_designer);
    }

    function removeDesigner(address _designer) external onlyAdmin {
        if (!_designers[_designer]) {
            revert AddressInvalid();
        }
        _designers[_designer] = false;
        emit DesignerRemoved(_designer);
    }

    function addOpenAction(address _openAction) external onlyAdmin {
        if (_openActions[_openAction]) {
            revert Existing();
        }
        _openActions[_openAction] = true;
        emit OpenActionAdded(_openAction);
    }

    function removeOpenAction(address _openAction) external onlyAdmin {
        if (!_openActions[_openAction]) {
            revert AddressInvalid();
        }
        _openActions[_openAction] = false;
        emit OpenActionRemoved(_openAction);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isDesigner(address _address) public view returns (bool) {
        return _designers[_address];
    }

    function isOpenAction(address _address) public view returns (bool) {
        return _openActions[_address];
    }
}
