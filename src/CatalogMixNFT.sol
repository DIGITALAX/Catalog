// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CatalogMix is ERC721 {
    uint256 private _counter;

    struct Mix {
        uint256[] childTokens;
        bool isChild;
        uint256 parentToken;
    }

    mapping(uint256 => Mix) public mixes;

    constructor() ERC721("MixNFT", "MNFT") {
        _counter = 0;
    }

    function mint(address to, uint256[] memory childTokenIds) public {
        _counter += 1;
        _mint(to, _counter);

        for (uint256 i = 0; i < childTokenIds.length; i++) {
            uint256 childTokenId = childTokenIds[i];
            require(
                ownerOf(childTokenId) == msg.sender,
                "Only owner can add child tokens"
            );
            mixes[childTokenId].isChild = true;
            mixes[childTokenId].parentToken = _counter;
            _transfer(msg.sender, address(this), childTokenId);
        }

        mixes[_counter] = Mix(childTokenIds, false, 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);

        if (!mixes[tokenId].isChild) {
            Mix memory mix = mixes[tokenId];
            for (uint256 i = 0; i < mix.childTokens.length; i++) {
                uint256 childTokenId = mix.childTokens[i];
                _transfer(address(this), to, childTokenId);
            }
        } else {
            uint256 parentTokenId = mixes[tokenId].parentToken;
            uint256[] storage childTokens = mixes[parentTokenId].childTokens;
            for (uint256 i = 0; i < childTokens.length; i++) {
                if (childTokens[i] == tokenId) {
                    childTokens[i] = childTokens[childTokens.length - 1];
                    childTokens.pop();
                    break;
                }
            }
            mixes[tokenId].isChild = false;
            mixes[tokenId].parentToken = 0;
        }
    }

    function burn(uint256 tokenId) public {
        if (!mixes[tokenId].isChild) {
            Mix memory mix = mixes[tokenId];
            for (uint256 i = 0; i < mix.childTokens.length; i++) {
                uint256 childTokenId = mix.childTokens[i];
                _burn(childTokenId);
                delete mixes[childTokenId];
            }
        }
        _burn(tokenId);
        delete mixes[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (mixes[tokenId].isChild && from != address(this)) {
            revert("Child tokens can only be transferred from contract");
        }
    }
}
