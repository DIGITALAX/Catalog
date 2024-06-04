// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./AutographMarket.sol";

contract AutographCollection is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    AutographMarket public autographMarket;

    error AddressNotVerified();
    error NotEditable();

    modifier OnlyDesigner() {
        if (!autographAccessControl.isDesigner(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    modifier OnlyMarket() {
        if (msg.sender != address(autographMarket)) {
            revert AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress,
        address _autographDataAddress,
        address _autographMarketAddress
    ) ERC721("AutographCollection", "ACNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
        autographData = AutographData(_autographDataAddress);
        autographMarket = AutographMarket(_autographMarketAddress);
    }

    function createGallery(
        AutographLibrary.CollectionInit memory _colls,
        address _designer
    ) public OnlyDesigner {
        autographData.createGallery(
            AutographLibrary.CollectionInit({
                prices: _colls.prices,
                acceptedTokens: _colls.acceptedTokens,
                uris: _colls.uris,
                amounts: _colls.amounts,
                collectionTypes: _colls.collectionTypes
            }),
            _designer
        );
    }

    function deleteGallery(uint16 _galleryId) public OnlyDesigner {
        if (!autographData.getGalleryEditable(_galleryId)) {
            revert NotEditable();
        }

        autographData.getMintedCollectionIdsByGalleryId();
    }

    function deleteCollection(
        uint256 _collectionId,
        uint16 _galleryId
    ) public OnlyDesigner {
        uint256[] memory _minted = autographData.getMintedTokenIdsByGalleryId(
            _collectionId,
            _galleryId
        );
        if (_minted.length > 1) {
            revert NotEditable();
        }
        autographData.deleteCollection(_collectionId, _galleryId);
    }

    function mintCollection() external OnlyMarket {}
}
