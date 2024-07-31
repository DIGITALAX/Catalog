// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./NPCLibrary.sol";

contract NPCControls {
    AutographAccessControl public accessControl;
    uint256 public npcCount;
    uint256 public moduleCount;
    address public npcAU;
    mapping(string => NPCLibrary.NPC) private _npcs;
    mapping(string => mapping(address => uint256[])) private _npcModuleIds;
    mapping(string => address[]) private _npcCreators;

    event NPCInitialized(string name);
    event NPCEdited(string name);
    event ActivityModuleAdded(address creator, uint256 moduleId);
    event ActivityModuleUpdated(address creator, uint256 moduleId);
    event ActivityModuleRemoved(address creator, uint256 moduleId);

    error NPCAlreadyRegistered();
    error OnlyAdmin();
    error OnlyNPCAu();

    constructor(address _accessControl, address _npcAU) {
        accessControl = AutographAccessControl(_accessControl);
        npcAU = _npcAU;
    }

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier OnlyNPCAU() {
        if (msg.sender != npcAU) {
            revert OnlyNPCAu();
        }
        _;
    }

    function initializeNPC(
        string[] memory _scenes,
        string memory _name,
        string memory _spriteSheet
    ) public onlyAdmin {
        if (_npcs[_name].isRegistered) {
            revert NPCAlreadyRegistered();
        }
        _npcs[_name].isRegistered = true;
        _npcs[_name].spriteSheet = _spriteSheet;
        _npcs[_name].scenes = _scenes;
        npcCount++;
        emit NPCInitialized(_name);
    }

    function editNPC(
        string[] memory _scenes,
        string memory _name,
        string memory _spriteSheet
    ) public onlyAdmin {
        _npcs[_name].isRegistered = true;
        _npcs[_name].spriteSheet = _spriteSheet;
        _npcs[_name].scenes = _scenes;
        emit NPCEdited(_name);
    }

    function addActivityModule(
        NPCLibrary.ActivityModule memory _module,
        string memory _npc,
        address _creator
    ) external OnlyNPCAU {
        moduleCount++;

        _npcs[_npc].activityModules[_creator][moduleCount] = _module;

        if (
            _npcCreators[_npc].length == 0 ||
            _npcCreators[_npc][_npcCreators[_npc].length - 1] != _creator
        ) {
            _npcCreators[_npc].push(_creator);
        }
        _npcModuleIds[_npc][_creator].push(moduleCount);

        emit ActivityModuleAdded(_creator, moduleCount);
    }

    function addToExistingActivity(
        string memory _npc,
        address _creator,
        uint256 _moduleCount,
        uint256 _outfitAmount,
        uint256 _productPostAmount,
        uint256 _profileInteractionAmount,
        uint256 _expiration
    ) external OnlyNPCAU {
        _npcs[_npc]
        .activityModules[_creator][moduleCount].outfitAmount = _outfitAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount]
            .profileInteractionAmount = _profileInteractionAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount]
            .productPostAmount = _productPostAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount].expiration = _expiration;

        emit ActivityModuleUpdated(_creator, _moduleCount);
    }

    function isActivityModuleExpired(
        string memory _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (bool) {
        return
            block.timestamp >
            _npcs[_npc].activityModules[_creator][_moduleId].expiration;
    }

    function isTimeToUpdateOutfit(
        string memory _npc,
        address _creator,
        uint256 _moduleId
    ) public returns (bool) {
        NPCLibrary.ActivityModule storage _module = _npcs[_npc].activityModules[
            _creator
        ][_moduleId];

        if (
            block.timestamp > _module.expiration ||
            block.timestamp <
            _module.lastUpdateOutfit + 24 hours / _module.outfitAmount
        ) {
            return false;
        }

        if (_module.outfitCycleFrequency >= _module.outfitAmount) {
            _module.outfitCycleFrequency = 0;
        } else {
            _module.outfitCycleFrequency++;
        }

        _module.lastUpdateOutfit = block.timestamp;

        return true;
    }

    function isTimeToUpdateProduct(
        string memory _npc,
        address _creator,
        uint256 _moduleId
    ) public returns (bool) {
        NPCLibrary.ActivityModule storage _module = _npcs[_npc].activityModules[
            _creator
        ][_moduleId];

        if (
            block.timestamp > _module.expiration ||
            block.timestamp <
            _module.lastUpdateProduct + 24 hours / _module.productPostAmount
        ) {
            return false;
        }

        if (_module.productCycleFrequency >= _module.productPostAmount) {
            _module.productPostAmount = 0;
        } else {
            _module.productCycleFrequency++;
        }

        _module.lastUpdateProduct = block.timestamp;

        return true;
    }

    function isTimeToUpdateInteraction(
        string memory _npc,
        address _creator,
        uint256 _moduleId
    ) public returns (bool) {
        NPCLibrary.ActivityModule storage _module = _npcs[_npc].activityModules[
            _creator
        ][_moduleId];

        if (
            block.timestamp > _module.expiration ||
            block.timestamp <
            _module.lastUpdateInteraction +
                24 hours /
                _module.profileInteractionAmount
        ) {
            return false;
        }

        if (
            _module.interactionCycleFrequency >=
            _module.profileInteractionAmount
        ) {
            _module.profileInteractionAmount = 0;
        } else {
            _module.interactionCycleFrequency++;
        }

        _module.lastUpdateInteraction = block.timestamp;

        return true;
    }

    function cleanupExpiredActivityModules(
        string memory _npc
    ) public onlyAdmin {
        for (uint i = 0; i < _npcCreators[_npc].length; i++) {
            address creator = _npcCreators[_npc][i];
            uint256[] storage moduleIds = _npcModuleIds[_npc][creator];

            for (uint j = 0; j < moduleIds.length; j++) {
                uint256 moduleId = moduleIds[j];
                if (isActivityModuleExpired(_npc, creator, moduleId)) {
                    delete _npcs[_npc].activityModules[creator][moduleId];

                    moduleIds[j] = moduleIds[moduleIds.length - 1];
                    moduleIds.pop();
                    j--;

                    emit ActivityModuleRemoved(creator, moduleId);
                }
            }

            if (moduleIds.length == 0) {
                _npcCreators[_npc][i] = _npcCreators[_npc][
                    _npcCreators[_npc].length - 1
                ];
                _npcCreators[_npc].pop();
                i--;
            }
        }
    }
}
