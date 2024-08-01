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
    address public governance;
    address public mona;
    string public symbol;
    string public name;
    NPCLibrary.ActivityBaseValues private _baseValues;

    error InvalidCreator();
    error InvalidAddress();

    constructor(
        NPCLibrary.ActivityBaseValues memory _base,
        address _npcControls,
        address _treasury,
        address _accessControl,
        address _npcAu,
        address _governance
    ) {
        npcControls = NPCControls(_npcControls);
        accessControl = AutographAccessControl(_accessControl);
        npcAU = NPCAU(_npcAu);
        name = "NPCModule";
        symbol = "NPCM";
        _baseValues = _base;
        governance = _governance;
        treasury = _treasury;
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

    modifier OnlyGovernance() {
        if (msg.sender != governance) {
            revert InvalidAddress();
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
        (uint256 _monaAmount, uint256 _auAmount) = _calculateAmount(
            _module.outfitAmount,
            _module.productPostAmount,
            _module.interactionAmount,
            _module.expiration
        );

        IERC20(mona).transferFrom(msg.sender, treasury, _monaAmount);

        npcControls.addActivityModule(_module, _npc, msg.sender, _auAmount);
    }

    function _calculateAmount(
        uint256 _outfitAmount,
        uint256 _productPostAmount,
        uint256 _interactionAmount,
        uint256 _expiration
    ) internal returns (uint256, uint256) {}

    function updateSpectated(
        address _npc,
        uint256 _moduleId,
        bool _spectate
    ) public OnlyCreator(_npc, _moduleId) {
        npcControls.spectateModule(_npc, msg.sender, _moduleId, _spectate);
    }

    function updateActivityModule(
        address _npc,
        uint256 _moduleId,
        uint256 _outfitAmount,
        uint256 _productPostAmount,
        uint256 _interactionAmount,
        uint256 _expiration,
        bool _live
    ) public OnlyCreator(_npc, _moduleId) {
        (uint256 _monaAmount, uint256 _auAmount) = _calculateAmount(
            _outfitAmount,
            _productPostAmount,
            _interactionAmount,
            _expiration
        );

        IERC20(mona).transferFrom(msg.sender, treasury, _monaAmount);

        npcControls.addToExistingActivity(
            _npc,
            msg.sender,
            _moduleId,
            _outfitAmount,
            _productPostAmount,
            _interactionAmount,
            _expiration,
            _auAmount,
            _live
        );
    }

    function spectateActivityModule(
        address _npc,
        address _creator,
        uint256 _moduleId,
        uint256 _chosenAUAmount
    ) public {
        uint256 _amount = _chosenAUAmount;

        (uint256 _monaAmount, uint256 _auAmount) = _calculateAmount(
            npcControls.getNPCModuleOutfitAmount(_npc, _creator, _moduleId),
            npcControls.getNPCModuleProductPostAmount(
                _npc,
                _creator,
                _moduleId
            ),
            npcControls.getNPCModuleProductInteractionAmount(
                _npc,
                _creator,
                _moduleId
            ),
            npcControls.getNPCModuleExpiration(_npc, _creator, _moduleId)
        );

        IERC20(mona).transferFrom(msg.sender, treasury, _monaAmount);

        if (_amount == 0) {
            _amount = _auAmount;
        }

        npcControls.chargeSpectatedModule(_npc, _creator, _moduleId, _amount);
    }

    function updateBaseValues(
        NPCLibrary.ActivityBaseValues memory _base
    ) external OnlyGovernance {
        _baseValues = _base;
    }

    function retireActivityModule(
        address _npc,
        uint256 _moduleId
    ) public OnlyCreator(_npc, _moduleId) {
        npcControls.removeActivityModule(_npc, msg.sender, _moduleId);
    }

    function setTreasuryAddress(address _treasury) public OnlyAdmin {
        treasury = _treasury;
    }

    function setMONAAddress(address _mona) public OnlyAdmin {
        mona = _mona;
    }

    function getBaseExpiration() public view returns (uint256) {
        return _baseValues.expiration;
    }

    function getBaseOutfitFrequencyPerDay() public view returns (uint256) {
        return _baseValues.outfitFrequencyPerDay;
    }

    function getBasePerProduct() public view returns (uint256) {
        return _baseValues.perProduct;
    }

    function getBasePerInteractionProfile() public view returns (uint256) {
        return _baseValues.perInteractionProfile;
    }

    function getBaseProductFrequencyPerDay() public view returns (uint256) {
        return _baseValues.productFrequencyPerDay;
    }

    function getBaseInteractionFrequencyPerDay() public view returns (uint256) {
        return _baseValues.interactionFrequencyPerDay;
    }

    function getBasePersonality() public view returns (uint256) {
        return _baseValues.personality;
    }

    function getBaseLanguage() public view returns (uint256) {
        return _baseValues.language;
    }

    function getBaseModel() public view returns (uint256) {
        return _baseValues.model;
    }
}

// patron nfts (spectated) añade esto en el código
// governance vota todas las cuatras semanas (una vez cada mes)
// cómo poner el uri dentro del nft al mintearlo con un lienzo de javascript
// el AU se envia al NFT y cada día se disminuye el au
// cada npc tiene un límite del trabajo > la gobernanica lo puede cambiar
