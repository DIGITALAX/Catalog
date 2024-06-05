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
    uint256 private _supply;

    error AddressNotVerified();
    error NotEditable();

    mapping(uint256 => AutographLibrary.CollectionMap) _collectionMap;

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

        autographData.deleteGallery(msg.sender, _galleryId);
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

    function addCollections(
        AutographLibrary.CollectionInit memory _colls,
        uint16 _galleryId
    ) public OnlyDesigner {
        autographData.addCollections(_colls, msg.sender, _galleryId);
    }

    function mintCollection(
        address _purchaserAddress,
        uint256 _collectionId,
        uint16 _galleryId
    ) external OnlyMarket {
        _supply++;
        _safeMint(_purchaserAddress, _supply);

        _collectionMap[_supply] = AutographLibrary.CollectionMap({
            collectionId: _collectionId,
            galleryId: _galleryId
        });

        autographData.setMintedTokens(_supply, _collectionId, _galleryId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        AutographLibrary.CollectionMap memory info = _collectionMap[_tokenId];

        return
            autographData.getCollectionURIByGalleryId(
                info.collectionId,
                info.galleryId
            );
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }
}
