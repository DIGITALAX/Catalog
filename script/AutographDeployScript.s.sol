// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import "../src/AutographData.sol";
import "../src/AutographNFT.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographCollection.sol";
import "../src/AutographOpenAction.sol";
import "../src/NPCPublication.sol";

contract AutographDeployScript is Script {
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollection public autographCollection;
    AutographMarket public autographMarket;
    AutographOpenAction public autographOpenAction;
    AutographNFT public autographNFT;
    NPCPublication public npcPublication;
    address hub_amoy = 0xA2574D9DdB6A325Ad2Be838Bd854228B80215148;
    address hub = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address moduleGlobals_amoy = 0x9E81eD8099dF82004D298144138C12AbB959DF1E;
    address moduleGlobals = 0x1eD5983F0c883B96f7C35528a1e22EEA67DE3Ff9;
    address printSplitsData_amoy = 0x8402e22e4712acc9Bb91Fbec752881c4F9f21b1D;
    address printSplitsData = 0x5A4A9a99d4736aE024044d17AA989426C76fafFD;
    address usd = 0x29244d4cb549c35A9E634b262e62a49Aa7A14B80;
    address mona = 0x5dd9A1636B221b45043B040a72F4229F8D66e40D;
    address eth = 0xc4414EBA4Caa899F52463aa232E451AC31d00Ed3;
    address matic = 0x1f83476Ed25E5Ca2e32DF06B8d1E59Da38F25CCA;
    address fulfiller = 0x3D1f8A6D6584a1672d2817368783B9a2a36ae361;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        accessControl = new AutographAccessControl();
        autographNFT = new AutographNFT(address(accessControl));
        autographMarket = new AutographMarket(
            "AMAR",
            "Autograph Market",
            address(accessControl),
            address(printSplitsData),
            address(autographNFT)
        );
        autographCollection = new AutographCollection(address(accessControl));
        autographData = new AutographData(
            "ADATA",
            "Autograph Data",
            address(accessControl),
            address(autographCollection),
            address(autographMarket),
            address(autographNFT)
        );
        autographOpenAction = new AutographOpenAction(
            "metadata",
            hub,
            moduleGlobals,
            address(autographData),
            address(accessControl),
            address(autographMarket)
        );
        npcPublication = new NPCPublication(
            "NPCP",
            "NPC Publication",
            address(accessControl),
            address(autographData)
        );

        accessControl.setFulfiller(fulfiller);
        autographData.setShirtBase(50000000000000000000);
        autographData.setHoodieBase(60000000000000000000);
        autographData.setVig(5);
        autographCollection.setAutographData(address(autographData));
        autographCollection.setAutographMarket(address(autographMarket));
        autographMarket.setAutographCollection(address(autographCollection));
        autographMarket.setAutographData(address(autographData));
        autographNFT.setAutographData(address(autographData));
        autographNFT.setAutographMarketAddress(address(autographMarket));
        autographCollection.setParentMixURI("parentURI");
        
        vm.stopBroadcast();

        console.log(
            address(accessControl),
            address(autographNFT),
            address(autographMarket)
        );
        console.log(
            address(autographCollection),
            address(autographData),
            address(autographOpenAction)
        );
        console.log(address(npcPublication));
    }
}
