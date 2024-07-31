// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./NPCControls.sol";
import "./NPCLibrary.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AutographAccessControl.sol";
import "./NPCAU.sol";

contract NPCModule {
    AutographAccessControl public accessControl;
    NPCAU public npcAU;
    NPCControls public npcControls;
    address public treasury;
    address public mona;
    string public symbol;
    string public name;

    error InvalidCreator();
    error InvalidAddress();

    constructor(
        address _npcControls,
        address _treasury,
        address _accessControl,
        address _npcAu
    ) {
        npcControls = NPCControls(_npcControls);
        accessControl = AutographAccessControl(_accessControl);
        npcAU = NPCAU(_npcAu);
        name = "NPCModule";
        symbol = "NPCM";
    }

    modifier OnlyCreator(address _npc, uint256 _moduleId) {
        if (
            msg.sender !=
            npcControls.getNPCModuleArtist(_npc, msg.sender, _moduleId)
        ) {
            revert InvalidCreator();
        }
        _;
    }

    modifier OnlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    function mintActivityModule(
        NPCLibrary.ActivityModule memory _module,
        address _npc
    ) public {
        // compra + edita el npc y su metadata etc.

        IERC20(mona).transferFrom(msg.sender, treasury, _amount);

        npcAU.mintActivityModule();

        npcControls.addActivityModule(_module, _npc, msg.sender);
    }

    function updateActivityModule(
        address _npc,
        uint256 _moduleId,
        uint256 _outfitAmount,
        uint256 _productPostAmount,
        uint256 _interactionAmount,
        uint256 _expiration
    ) public OnlyCreator(_npc, _moduleId) {
        IERC20(mona).transferFrom(msg.sender, treasury, _amount);

        npcAU.mintAdditionalAU();

        npcControls.addToExistingActivity(
            _npc,
            msg.sender,
            _moduleId,
            _outfitAmount,
            _productPostAmount,
            _interactionAmount,
            _expiration
        );
    }

    function retireActivityModule(
        address _npc,
        uint256 _moduleId
    ) public OnlyCreator(_npc, _moduleId) {
        npcControls.removeActivityModule(_npc, msg.sender);
    }

    function setTreasuryAddress(address _treasury) public OnlyAdmin {
        treasury = _treasury;
    }

    function setMONAAddress(address _mona) public OnlyAdmin {
        mona = _mona;
    }
}
