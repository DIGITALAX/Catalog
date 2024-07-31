// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

contract NPCLibrary {
    struct ActivityModule {
        uint256[] products;
        uint256[] interactionProfiles;
        string languages;
        string topics;
        string outfit;
        string model;
        string personality;
        address artist;
        uint256 expiration;
        uint256 productPostAmount;
        uint256 profileInteractionAmount;
        uint256 outfitAmount;
        uint256 lastUpdateOutfit;
        uint256 lastUpdateProduct;
        uint256 lastUpdateInteraction;
        uint256 outfitCycleFrequency;
        uint256 productCycleFrequency;
        uint256 interactionCycleFrequency;
    }

    struct NPC {
        mapping(address => mapping(uint256 => ActivityModule)) activityModules;
        string[] scenes;
        string spriteSheet;
        bool isRegistered;
    }
}
