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
        uint16 _galleryId,
        uint8 _amount
    ) external OnlyMarket {
        for (uint8 i = 0; i < _amount; i++) {
            _supply++;
            _safeMint(_purchaserAddress, _supply);

            _collectionMap[_supply] = AutographLibrary.CollectionMap({
                collectionId: _collectionId,
                galleryId: _galleryId
            });

            autographData.setMintedTokens(_supply, _collectionId, _galleryId);
        }
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
    ) external OnlyMarket {
        _supply++;
        _safeMint(_purchaserAddress, _supply);
        uint256 _parentId = _supply;

        for (uint256 i = 0; i < _collections.length; i++) {
            _supply++;
            _safeMint(_purchaserAddress, _supply);
            _childNFTs[_parentId].push(_supply);
            _parentNFT[_supply] = _parentId;

            _collectionMap[_supply] = AutographLibrary.CollectionMap({
                collectionId: _collections[i],
                galleryId: _galleries[i]
            });

            autographData.setMintedTokens(
                _supply,
                _collections[i],
                _galleries[i]
            );
        }
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
        if (_childNFTs[_tokenId].length > 0) {
            if (ownerOf(_tokenId) != msg.sender) {
                revert AddressNotVerified();
            }
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
}
