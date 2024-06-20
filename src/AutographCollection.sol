// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
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
    error InvalidParent();
    error NotGalleryDesigner();

    mapping(uint256 => AutographLibrary.CollectionMap) _collectionMap;
    mapping(uint256 => uint256) private _parentNFT;
    mapping(uint256 => uint256[]) private _childNFTs;

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

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress
    ) ERC721("AutographCollection", "ACNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
    }

    function createGallery(
        AutographLibrary.CollectionInit memory _colls
    ) public OnlyDesigner {
        autographData.createGallery(
            AutographLibrary.CollectionInit({
                prices: _colls.prices,
                acceptedTokens: _colls.acceptedTokens,
                uris: _colls.uris,
                amounts: _colls.amounts,
                collectionTypes: _colls.collectionTypes
            }),
            msg.sender
        );
    }

    function deleteGallery(uint16 _galleryId) public OnlyDesigner {
        uint256[] memory _collections = autographData.getGalleryCollections(
            _galleryId
        );

        if (
            msg.sender !=
            autographData.getCollectionDesignerByGalleryId(_collections[0], 1)
        ) {
            revert NotGalleryDesigner();
        }

        if (!autographData.getGalleryEditable(_galleryId)) {
            revert NotEditable();
        }

        autographData.deleteGallery(msg.sender, _galleryId);
    }

    function deleteCollection(
        uint256 _collectionId,
        uint16 _galleryId
    ) public OnlyDesigner {
        uint256[] memory _collections = autographData.getGalleryCollections(
            _galleryId
        );

        if (
            msg.sender !=
            autographData.getCollectionDesignerByGalleryId(
                _collections[0],
                _galleryId
            )
        ) {
            revert NotGalleryDesigner();
        }

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
        uint256[] memory _collections = autographData.getGalleryCollections(
            _galleryId
        );

        if (
            msg.sender !=
            autographData.getCollectionDesignerByGalleryId(
                _collections[0],
                _galleryId
            )
        ) {
            revert NotGalleryDesigner();
        }

        autographData.addCollections(_colls, msg.sender, _galleryId);
    }

    function mintCollection(
        address _purchaserAddress,
        uint256 _collectionId,
        uint16 _galleryId,
        uint8 _amount
    ) external OnlyMarket returns (uint256[] memory) {
        uint256[] memory _tokenIds = new uint256[](_amount);
        uint256[] memory _collectionIds = new uint256[](_amount);
        uint16[] memory _galleryIds = new uint16[](_amount);

        for (uint8 i = 0; i < _amount; i++) {
            _supply++;
            _safeMint(_purchaserAddress, _supply);
            _tokenIds[i] = _supply;
            _galleryIds[i] = _galleryId;
            _collectionIds[i] = _collectionId;
            _collectionMap[_supply] = AutographLibrary.CollectionMap({
                collectionId: _collectionId,
                galleryId: _galleryId
            });
        }

        autographData.setMintedTokens(
            _tokenIds,
            _collectionIds,
            _galleryIds,
            _amount
        );

        return _tokenIds;
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

    function mintMix(
        uint256[] memory _collections,
        uint16[] memory _galleries,
        address _purchaserAddress
    ) external OnlyMarket returns (uint256[] memory, uint256) {
        _supply++;
        _safeMint(_purchaserAddress, _supply);
        uint256 _parentId = _supply;
        uint256[] memory _childIds = new uint256[](_collections.length);

        for (uint256 i = 0; i < _collections.length; i++) {
            _supply++;
            _childIds[i] = _supply;
            _safeMint(_purchaserAddress, _supply);
            _childNFTs[_parentId].push(_supply);
            _parentNFT[_supply] = _parentId;

            _collectionMap[_supply] = AutographLibrary.CollectionMap({
                collectionId: _collections[i],
                galleryId: _galleries[i]
            });
        }
        
        autographData.setMintedTokens(_childIds, _collections, _galleries, 1);
        return (_childIds, _parentId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(IERC721, ERC721) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert AddressNotVerified();
        }

        if (_childNFTs[_tokenId].length > 0) {
            for (uint256 i = 0; i < _childNFTs[_tokenId].length; i++) {
                uint256 _childId = _childNFTs[_tokenId][i];
                _transfer(_from, _to, _childId);
            }
        }

        _transfer(_from, _to, _tokenId);

        if (_parentNFT[_tokenId] != 0) {
            uint256 _parentId = _parentNFT[_tokenId];
            for (uint256 i = 0; i < _childNFTs[_parentId].length; i++) {
                if (_childNFTs[_parentId][i] == _tokenId) {
                    _childNFTs[_parentId][i] = _childNFTs[_parentId][
                        _childNFTs[_parentId].length - 1
                    ];
                    _childNFTs[_parentId].pop();
                    break;
                }
            }
            _parentNFT[_tokenId] = 0;
        }
    }

    function transferChild(
        address _from,
        address _to,
        uint256 _childId
    ) public {
        if (ownerOf(_childId) != msg.sender) {
            revert AddressNotVerified();
        }

        uint256 _parentId = _parentNFT[_childId];
        _transfer(_from, _to, _childId);

        if (_parentId != 0) {
            for (uint256 i = 0; i < _childNFTs[_parentId].length; i++) {
                if (_childNFTs[_parentId][i] == _childId) {
                    _childNFTs[_parentId][i] = _childNFTs[_parentId][
                        _childNFTs[_parentId].length - 1
                    ];
                    _childNFTs[_parentId].pop();
                    break;
                }
            }
            _parentNFT[_childId] = 0;
        }
    }

    function burn(uint256 _tokenId) public {
        if (ownerOf(_tokenId) != msg.sender) {
            revert AddressNotVerified();
        }

        if (_childNFTs[_tokenId].length > 0) {
            for (uint256 i = 0; i < _childNFTs[_tokenId].length; i++) {
                uint256 _childId = _childNFTs[_tokenId][i];
                _burn(_childId);
            }
            delete _childNFTs[_tokenId];
        }

        if (_parentNFT[_tokenId] != 0) {
            uint256 _parentId = _parentNFT[_tokenId];
            for (uint256 i = 0; i < _childNFTs[_parentId].length; i++) {
                if (_childNFTs[_parentId][i] == _tokenId) {
                    _childNFTs[_parentId][i] = _childNFTs[_parentId][
                        _childNFTs[_parentId].length - 1
                    ];
                    _childNFTs[_parentId].pop();
                    break;
                }
            }
            _parentNFT[_tokenId] = 0;
        }

        _burn(_tokenId);
    }

    function burnChild(uint256 _childId) public {
        if (ownerOf(_childId) != msg.sender) {
            revert AddressNotVerified();
        }

        uint256 _parentId = _parentNFT[_childId];
        _burn(_childId);

        if (_parentId != 0) {
            for (uint256 i = 0; i < _childNFTs[_parentId].length; i++) {
                if (_childNFTs[_parentId][i] == _childId) {
                    _childNFTs[_parentId][i] = _childNFTs[_parentId][
                        _childNFTs[_parentId].length - 1
                    ];
                    _childNFTs[_parentId].pop();
                    break;
                }
            }
            _parentNFT[_childId] = 0;
        }
    }

    function setAutographData(address _autographData) public OnlyAdmin {
        autographData = AutographData(_autographData);
    }

    function setAutographMarket(address _autographMarket) public OnlyAdmin {
        autographMarket = AutographMarket(_autographMarket);
    }
}
