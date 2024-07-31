// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./NPCControls.sol";

contract NPCGovernance {
    string public symbol;
    string public name;

    constructor(address _npcControls) {
        npcControls = _npcControls;
        name = "NPCGovernance";
        symbol = "NPCG";
    }

    function updateNPCs() public {
        npcControls.editNPC();
    }
}

// controla el precio de cada cosa + puntos de deducción en el precio al tener algo de actividad (lealtad) + otras cosas como seguidores en lens etc. etc.
// Contrato de votear/gobernar los valores bases y disponibles
/* 
    - aquellos con pode o genesis puede elegir y cambiar los defectos o base de algunas configuraciones con un voto etc. 
    - y también aquellos que guardan niveles diferentes de mona
*/
