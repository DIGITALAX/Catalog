// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

contract NPCLibrary {
    struct ActivityModule {
        uint256[] products;
        uint256[] interactionProfiles;
        uint256[] fundedAUAmounts;
        uint256[] fundedAUTimestamps;
        string uri;
        string languages;
        string topics;
        string outfit;
        string model;
        string personality;
        address artist;
        uint256 expiration;
        uint256 productPostAmount;
        uint256 interactionAmount;
        uint256 outfitAmount;
        uint256 lastUpdateOutfit;
        uint256 lastUpdateProduct;
        uint256 lastUpdateInteraction;
        uint256 outfitCycleFrequency;
        uint256 productCycleFrequency;
        uint256 interactionCycleFrequency;
        uint256 totalAUAmount;
        uint256 liveAUAmount;
        bool spectated;
        bool live;
    }

    struct ActivityBaseValues {
        uint256 outfitFrequencyPerDay;
        uint256 perProduct;
        uint256 perInteractionProfile;
        uint256 productFrequencyPerDay;
        uint256 interactionFrequencyPerDay;
        uint256 personality;
        uint256 language;
        uint256 model;
        uint256 expiration;
    }

    struct NPC {
        mapping(address => mapping(uint256 => ActivityModule)) activityModules;
        string[] scenes;
        string spriteSheet;
        bool isRegistered;
    }
}
