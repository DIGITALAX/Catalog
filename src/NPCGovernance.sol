// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./NPCControls.sol";
import "./NPCModule.sol";

contract NPCGovernance {
    NPCControls public npcControls;
    NPCModule public npcModule;
    string public symbol;
    string public name;
    uint256 private _lastVote;

    error Wait1Month();

    event MonthlyVote(uint256 voters);

    mapping(address => NPCLibrary.Vote) _voters;
    mapping(address => NPCLibrary.NPC) _currentNPCValues;

    constructor(address _npcControls, address _npcModule) {
        npcControls = NPCControls(_npcControls);
        name = "NPCGovernance";
        symbol = "NPCG";
        npcModule = NPCModule(_npcModule);
    }

    function setMonthlyVotedValues() public {
        if (block.timestamp < _lastVote + 2629746 seconds) {
            revert Wait1Month();
        }

        _lastVote = block.timestamp;

        npcModule.updateBaseValues();

        uint16 _npcCount = npcControls.getNPCCount();

        for (uint16 i = 1; i < _npcCount - 1; i++) {
            address _npcAddress = npcControls.getNPCAddressByCount(i);
            if (_npcAddress != address(0)) {
                npcControls.editNPC(
                    _currentNPCValues[_npcAddress].npcBaseValues,
                    _currentNPCValues[_npcAddress].scenes,
                    _currentNPCValues[_npcAddress].spriteSheet,
                    _npcAddress,
                    _currentNPCValues[_npcAddress].maxModules
                );
            }
        }

        emit MonthlyVote(_voters.length);
    }

    function getLastVoteSubmitted() public view returns (uint256) {
        return _lastVote;
    }
}
