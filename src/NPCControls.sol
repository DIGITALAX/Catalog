// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./NPCLibrary.sol";
import "./AUNFT.sol";

contract NPCControls {
    AutographAccessControl public accessControl;
    AUNFT public auNFT;
    string public symbol;
    string public name;
    address public npcModule;
    address public npcGovernance;
    uint256 public npcCount;
    uint256 public moduleCount;

    mapping(address => NPCLibrary.NPC) private _npcs;
    mapping(address => mapping(address => uint256[])) private _npcModuleIds;
    mapping(address => address[]) private _npcCreators;
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _tokenIdMap;

    event NPCInitialized(address npcAddress);
    event NPCEdited(address npcAddress);
    event ActivityModuleAdded(
        address creator,
        address npcAddress,
        uint256 moduleId,
        uint256 nftId
    );
    event ActivityModuleUpdated(
        address creator,
        address npcAddress,
        uint256 moduleId,
        uint256 nftId
    );
    event ActivityModuleRemoved(
        address creator,
        address npcAddress,
        uint256 moduleId
    );
    event OutfitUpdated(address creator, address npcAddress, uint256 moduleId);
    event ProductUpdated(address creator, address npcAddress, uint256 moduleId);
    event InteractionUpdated(
        address creator,
        address npcAddress,
        uint256 moduleId
    );

    error NPCAlreadyRegistered();
    error OnlyAdmin();
    error OnlyNPCAu();

    constructor(
        address _accessControl,
        address _npcModule,
        address _auNFT,
        address _npcGovernance
    ) {
        accessControl = AutographAccessControl(_accessControl);
        npcModule = _npcModule;
        npcGovernance = _npcGovernance;
        auNFT = AUNFT(_auNFT);
        name = "NPCControls";
        symbol = "NPCC";
    }

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender) && msg.sender != npcGovernance) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier OnlyNPCAU() {
        if (msg.sender != npcModule) {
            revert OnlyNPCAu();
        }
        _;
    }

    function initializeNPC(
        string[] memory _scenes,
        string memory _spriteSheet,
        address _npcAddress
    ) public onlyAdmin {
        if (_npcs[_npcAddress].isRegistered) {
            revert NPCAlreadyRegistered();
        }
        _npcs[_npcAddress].isRegistered = true;
        _npcs[_npcAddress].spriteSheet = _spriteSheet;
        _npcs[_npcAddress].scenes = _scenes;
        npcCount++;
        emit NPCInitialized(_npcAddress);
    }

    function editNPC(
        string[] memory _scenes,
        string memory _spriteSheet,
        address _npcAddress
    ) public onlyAdmin {
        _npcs[_npcAddress].isRegistered = true;
        _npcs[_npcAddress].spriteSheet = _spriteSheet;
        _npcs[_npcAddress].scenes = _scenes;
        emit NPCEdited(_npcAddress);
    }

    function addActivityModule(
        NPCLibrary.ActivityModule memory _module,
        string memory _uri,
        address _npc,
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

        uint256 _tokenId = auNFT.mint(_uri, _creator);

        _tokenIdMap[_npc][_creator][moduleCount] = _tokenId;

        emit ActivityModuleAdded(_creator, _npc, moduleCount, _tokenId);
    }

    function removeActivityModule(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) external OnlyNPCAU {
        uint256[] storage _moduleIds = _npcModuleIds[_npc][_creator];

        delete _npcs[_npc].activityModules[_creator][_moduleId];

        for (uint i = 0; i < _moduleIds.length; i++) {
            if (_moduleIds[i] == _moduleId) {
                _moduleIds[i] = _moduleIds[_moduleIds.length - 1];
                _moduleIds.pop();
                break;
            }
        }

        if (_moduleIds.length == 0) {
            address[] storage creators = _npcCreators[_npc];
            for (uint i = 0; i < creators.length; i++) {
                if (creators[i] == _creator) {
                    creators[i] = creators[creators.length - 1];
                    creators.pop();
                    break;
                }
            }
        }

        emit ActivityModuleRemoved(_creator, _npc, _moduleId);
    }

    function addToExistingActivity(
        address _npc,
        address _creator,
        uint256 _moduleId,
        uint256 _outfitAmount,
        uint256 _productPostAmount,
        uint256 _interactionAmount,
        uint256 _expiration
    ) external OnlyNPCAU {
        _npcs[_npc]
        .activityModules[_creator][moduleCount].outfitAmount = _outfitAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount]
            .interactionAmount = _interactionAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount]
            .productPostAmount = _productPostAmount;
        _npcs[_npc]
        .activityModules[_creator][moduleCount].expiration = _expiration;

        emit ActivityModuleUpdated(
            _creator,
            _npc,
            _moduleId,
            _tokenIdMap[_npc][_creator][moduleCount]
        );
    }

    function isActivityModuleExpired(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (bool) {
        return
            block.timestamp >
            _npcs[_npc].activityModules[_creator][_moduleId].expiration;
    }

    function isTimeToUpdateOutfit(
        address _npc,
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

        emit OutfitUpdated(_creator, _npc, _moduleId);

        return true;
    }

    function isTimeToUpdateProduct(
        address _npc,
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

        emit ProductUpdated(_creator, _npc, _moduleId);

        return true;
    }

    function isTimeToUpdateInteraction(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public returns (bool) {
        NPCLibrary.ActivityModule storage _module = _npcs[_npc].activityModules[
            _creator
        ][_moduleId];

        if (
            block.timestamp > _module.expiration ||
            block.timestamp <
            _module.lastUpdateInteraction + 24 hours / _module.interactionAmount
        ) {
            return false;
        }

        if (_module.interactionCycleFrequency >= _module.interactionAmount) {
            _module.interactionAmount = 0;
        } else {
            _module.interactionCycleFrequency++;
        }

        _module.lastUpdateInteraction = block.timestamp;

        emit InteractionUpdated(_creator, _npc, _moduleId);

        return true;
    }

    function cleanupExpiredActivityModules(address _npc) public onlyAdmin {
        for (uint i = 0; i < _npcCreators[_npc].length; i++) {
            address _creator = _npcCreators[_npc][i];
            uint256[] storage _moduleIds = _npcModuleIds[_npc][_creator];

            for (uint j = 0; j < _moduleIds.length; j++) {
                uint256 _moduleId = _moduleIds[j];
                if (isActivityModuleExpired(_npc, _creator, _moduleId)) {
                    delete _npcs[_npc].activityModules[_creator][_moduleId];

                    _moduleIds[j] = _moduleIds[_moduleIds.length - 1];
                    _moduleIds.pop();
                    j--;

                    emit ActivityModuleRemoved(_creator, _npc, _moduleId);
                }
            }

            if (_moduleIds.length == 0) {
                _npcCreators[_npc][i] = _npcCreators[_npc][
                    _npcCreators[_npc].length - 1
                ];
                _npcCreators[_npc].pop();
                i--;
            }
        }
    }

    function getNPCScenes(address _npc) public view returns (string[] memory) {
        return _npcs[_npc].scenes;
    }

    function getNPCSpriteSheet(
        address _npc
    ) public view returns (string memory) {
        return _npcs[_npc].spriteSheet;
    }

    function getNPCRegistered(address _npc) public view returns (bool) {
        return _npcs[_npc].isRegistered;
    }

    function getNPCModuleProducts(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256[] memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].products;
    }

    function getNPCModuleInteractions(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256[] memory) {
        return
            _npcs[_npc]
            .activityModules[_creator][_moduleId].interactionProfiles;
    }

    function getNPCModuleLanguages(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (string memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].languages;
    }

    function getNPCModuleTopics(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (string memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].topics;
    }

    function getNPCModuleOutfit(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (string memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].outfit;
    }

    function getNPCModuleModel(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (string memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].model;
    }

    function getNPCModulePersonality(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (string memory) {
        return _npcs[_npc].activityModules[_creator][_moduleId].personality;
    }

    function getNPCModuleArtist(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (address) {
        return _npcs[_npc].activityModules[_creator][_moduleId].artist;
    }

    function getNPCModuleExpiration(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256) {
        return _npcs[_npc].activityModules[_creator][_moduleId].expiration;
    }

    function getNPCModuleProductPostAmount(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256) {
        return
            _npcs[_npc].activityModules[_creator][_moduleId].productPostAmount;
    }

    function getNPCModuleProductInteractionAmount(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256) {
        return
            _npcs[_npc].activityModules[_creator][_moduleId].interactionAmount;
    }

    function getNPCModuleOutfitAmount(
        address _npc,
        address _creator,
        uint256 _moduleId
    ) public view returns (uint256) {
        return _npcs[_npc].activityModules[_creator][_moduleId].outfitAmount;
    }
}
