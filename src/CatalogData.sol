// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.23;

import "./CatalogAccessControl.sol";
import "./CatalogLibrary.sol";

contract PrintDesignData {
    CatalogAccessControl public catalogAccessControl;
    string public symbol;
    string public name;
    uint256 private _catalogCounter;

    error InvalidAddress();

    event CatalogCreated(uint256 catalogId, string uri, uint256 amount);

    modifier onlyOpenAction() {
        if (!catalogAccessControl.isOpenAction(msg.sender)) {
            revert InvalidAddress();
        }
        _;
    }

    mapping(uint256 => CatalogLibrary.Catalog) private _catalogs;

    constructor(
        string memory _symbol,
        string memory _name,
        address _catalogAccessControl
    ) {
        symbol = _symbol;
        name = _name;
        _catalogCounter = 0;
        catalogAccessControl = CatalogAccessControl(_catalogAccessControl);
    }

    function createCatalog(
        CatalogLibrary.Catalog memory _catalog
    ) external onlyOpenAction {
        _catalogs[_catalogCounter].id = _catalogCounter;
        _catalogs[_catalogCounter].uri = _catalog.uri;
        _catalogs[_catalogCounter].amount = _catalog.amount;
        _catalogs[_catalogCounter].prices = _catalog.prices;
        _catalogs[_catalogCounter].acceptedTokens = _catalog.acceptedTokens;

        _catalogCounter++;

        emit CatalogCreated(_catalog.id, _catalog.uri, _catalog.amount);
    }

    function getCatalogURIById(
        uint256 _catalogId
    ) public view returns (string memory) {
        return _catalogs[_catalogId].uri;
    }

    function getCatalogAmountById(
        uint256 _catalogId
    ) public view returns (uint256) {
        return _catalogs[_catalogId].amount;
    }

    function getCatalogPricesById(
        uint256 _catalogId
    ) public view returns (uint256[] memory) {
        return _catalogs[_catalogId].prices;
    }

    function getCatalogAcceptedTokensById(
        uint256 _catalogId
    ) public view returns (address[] memory) {
        return _catalogs[_catalogId].acceptedTokens;
    }
}
