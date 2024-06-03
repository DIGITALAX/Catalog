// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";

contract AutographData {
    AutographAccessControl public autographAccessControl;
    string public symbol;
    string public name;
    uint256 private _autographCounter;
    uint256 private _collectionCounter;

    error InvalidAddress();

    event AutographCreated(uint256 autographId, string uri, uint256 amount);
    event CollectionsCreated(uint256[] collectionIds, address designer);

    modifier onlyOpenAction() {
        if (!autographAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    mapping(uint256 => AutographLibrary.Autograph) private _autographs;
    mapping(address => AutographLibrary.Collection[]) private _collections;

    constructor(
        string memory _symbol,
        string memory _name,
        address _autographAccessControl
    ) {
        symbol = _symbol;
        name = _name;
        _autographCounter = 0;
        _collectionCounter = 0;
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function createAutograph(
        AutographLibrary.AutographInit memory _autograph
    ) external onlyOpenAction {
        _autographCounter++;

        _autographs[_autographCounter].id = _autographCounter;
        _autographs[_autographCounter].uri = _autograph.uri;
        _autographs[_autographCounter].amount = _autograph.amount;
        _autographs[_autographCounter].prices = _autograph.prices;
        _autographs[_autographCounter].acceptedTokens = _autograph
            .acceptedTokens;
        _autographs[_autographCounter].pubId = _autograph.pubId;
        _autographs[_autographCounter].profileId = _autograph.profileId;

        emit AutographCreated(
            _autographCounter,
            _autograph.uri,
            _autograph.amount
        );
    }

    function createCollection(
        AutographLibrary.CollectionInit memory _colls,
        address _designer
    ) external onlyOpenAction {
        for (uint8 i = 0; i < _colls.pubIds.length; i++) {
            _collectionCounter++;
            _collections[_designer][i].id = _collectionCounter;
            _collections[_designer][i].uri = _colls.uris[i];
            _collections[_designer][i].amount = _colls.amounts[i];
            _collections[_designer][i].prices = _colls.prices[i];
            _collections[_designer][i].acceptedTokens = _colls.acceptedTokens[
                i
            ];
            _collections[_designer][i].pubId = _colls.pubIds[i];
            _collections[_designer][i].profileId = _colls.profileIds[i];
            _collections[_designer][i].collectionType = _colls.collectionTypes[
                i
            ];
        }

        uint[] memory _amounts = new uint[](6);
        for (uint i = 0; i < _amounts.length; i++) {
            _amounts[i] = _collectionCounter + i;
        }
        emit CollectionsCreated(_amounts, _designer);
    }

    function getAutographURIById(
        uint256 _autographId
    ) public view returns (string memory) {
        return _autographs[_autographId].uri;
    }

    function getAutographAmountById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].amount;
    }

    function getAutographPricesById(
        uint256 _autographId
    ) public view returns (uint256[] memory) {
        return _autographs[_autographId].prices;
    }

    function getAutographAcceptedTokensById(
        uint256 _autographId
    ) public view returns (address[] memory) {
        return _autographs[_autographId].acceptedTokens;
    }

    function getAutographProfileIdById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].profileId;
    }

    function getAutographPubIdById(
        uint256 _autographId
    ) public view returns (uint256) {
        return _autographs[_autographId].pubId;
    }

    function getCollectionLengthByDesigner(
        address _designer
    ) public view returns (uint256) {
        return _collections[_designer].length;
    }

    function getCollectionURIByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (string memory) {
        return _collections[_designer][_id].uri;
    }

    function getCollectionAmountByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (uint256) {
        return _collections[_designer][_id].amount;
    }

    function getCollectionPricesByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (uint256[] memory) {
        return _collections[_designer][_id].prices;
    }

    function getCollectionAcceptedTokensByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (address[] memory) {
        return _collections[_designer][_id].acceptedTokens;
    }

    function getCollectionProfileIdByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (uint256) {
        return _collections[_designer][_id].profileId;
    }

    function getCollectionPubIdByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (uint256) {
        return _collections[_designer][_id].pubId;
    }

    function getCollectionTypeByDesignerId(
        address _designer,
        uint256 _id
    ) public view returns (AutographLibrary.CollectionType) {
        return _collections[_designer][_id].collectionType;
    }

    function getAutographCounter() public view returns (uint256) {
        return _autographCounter;
    }

    function getCollectionCounter() public view returns (uint256) {
        return _collectionCounter;
    }
}
