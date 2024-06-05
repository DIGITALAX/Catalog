// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.16;

contract PrintAccessControl {
    string public symbol;
    string public name;
    address public fiatPKPAddress;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _designers;
    mapping(address => bool) private _openActions;
    mapping(address => bool) private _fulfillers;
    mapping(address => bool) private _pkps;
    mapping(address => bool) private _communityStewards;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) _verifiedFiat;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event DesignerAdded(address indexed designer);
    event DesignerRemoved(address indexed designer);
    event OpenActionAdded(address indexed openAction);
    event OpenActionRemoved(address indexed openAction);
    event FulfillerAdded(address indexed fulfiller);
    event FulfillerRemoved(address indexed fulfiller);
    event PKPAdded(address indexed pkp);
    event PKPRemoved(address indexed pkp);
    event CommunityStewardAdded(address indexed pkp);
    event CommunityStewardRemoved(address indexed pkp);
    event VerifiedFiatAdded(address indexed verified);
    event VerifiedFiatRemoved(address indexed verified);

    error AddressInvalid();
    error Existing();
    error CantRemoveSelf();

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert AddressInvalid();
        }
        _;
    }

    modifier pkpOrAdmin() {
        if (!_admins[msg.sender] && msg.sender != fiatPKPAddress) {
            revert AddressInvalid();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "PAC";
        name = "PrintAccessControl";
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

    function addFulfiller(address _fulfiller) external onlyAdmin {
        if (_fulfillers[_fulfiller]) {
            revert Existing();
        }
        _fulfillers[_fulfiller] = true;
        emit FulfillerAdded(_fulfiller);
    }

    function removeFulfiller(address _fulfiller) external onlyAdmin {
        if (!_fulfillers[_fulfiller]) {
            revert AddressInvalid();
        }
        _fulfillers[_fulfiller] = false;
        emit FulfillerRemoved(_fulfiller);
    }

    function addPKP(address _pkp) external onlyAdmin {
        if (_pkps[_pkp]) {
            revert Existing();
        }
        _pkps[_pkp] = true;
        emit PKPAdded(_pkp);
    }

    function removePKP(address _pkp) external onlyAdmin {
        if (!_pkps[_pkp]) {
            revert AddressInvalid();
        }
        _pkps[_pkp] = false;
        emit PKPRemoved(_pkp);
    }

    function addCommunitySteward(address _communitySteward) external onlyAdmin {
        if (_communityStewards[_communitySteward]) {
            revert Existing();
        }
        _communityStewards[_communitySteward] = true;
        emit CommunityStewardAdded(_communitySteward);
    }

    function removeCommunitySteward(
        address _communitySteward
    ) external onlyAdmin {
        if (!_communityStewards[_communitySteward]) {
            revert AddressInvalid();
        }
        _communityStewards[_communitySteward] = false;
        emit CommunityStewardRemoved(_communitySteward);
    }

    function addVerifiedFiat(
        address _verified,
        uint256 _pubId,
        uint256 _profileId
    ) external pkpOrAdmin {
        if (_verifiedFiat[_verified][_profileId][_pubId]) {
            revert Existing();
        }
        _verifiedFiat[_verified][_profileId][_pubId] = true;
        emit VerifiedFiatAdded(_verified);
    }

    function removeVerifiedFiat(
        address _verified,
        uint256 _pubId,
        uint256 _profileId
    ) external pkpOrAdmin {
        if (!_verifiedFiat[_verified][_profileId][_pubId]) {
            revert AddressInvalid();
        }
        _verifiedFiat[_verified][_profileId][_pubId] = false;
        emit VerifiedFiatRemoved(_verified);
    }

    function setFiatPKPAddress(address _newFiatPKPAddress) public onlyAdmin {
        fiatPKPAddress = _newFiatPKPAddress;
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isOpenAction(address _address) public view returns (bool) {
        return _openActions[_address];
    }

    function isDesigner(address _address) public view returns (bool) {
        return _designers[_address];
    }

    function isFulfiller(address _address) public view returns (bool) {
        return _fulfillers[_address];
    }

    function isPKP(address _address) public view returns (bool) {
        return _pkps[_address];
    }

    function isCommunitySteward(address _address) public view returns (bool) {
        return _communityStewards[_address];
    }

    function isVerifiedFiat(
        address _address,
        uint256 _profileId,
        uint256 _pubId
    ) public view returns (bool) {
        return _verifiedFiat[_address][_profileId][_pubId];
    }
}
