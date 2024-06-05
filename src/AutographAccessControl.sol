// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.23;

contract AutographAccessControl {
    string public symbol;
    string public name;
    address private _fulfiller;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _designers;
    mapping(address => bool) private _openActions;
    mapping(address => bool) private _npcs;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event DesignerAdded(address indexed designer);
    event DesignerRemoved(address indexed designer);
    event OpenActionAdded(address indexed openAction);
    event OpenActionRemoved(address indexed openAction);
    event NPCAdded(address indexed npc);
    event NPCRemoved(address indexed npc);

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
        name = "AutographAccessControl";
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

    function addNPC(address _npc) external onlyAdmin {
        if (_npcs[_npc]) {
            revert Existing();
        }
        _npcs[_npc] = true;
        emit NPCAdded(_npc);
    }

    function removeNPC(address _npc) external onlyAdmin {
        if (!_npcs[_npc]) {
            revert AddressInvalid();
        }
        _npcs[_npc] = false;
        emit NPCRemoved(_npc);
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

    function setFulfiller(address _fulfillerAddress) external onlyAdmin {
        _fulfiller = _fulfillerAddress;
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

    function isNPC(address _address) public view returns (bool) {
        return _npcs[_address];
    }

    function getFulfiller() public view returns (address) {
        return _fulfiller;
    }
}
