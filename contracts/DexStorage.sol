// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DataTypes.sol";

contract DexStorage is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Mapping of presale ID to Presale struct
    mapping(uint256 => DataTypes.Presale) public presales;

    // Counter for presale IDs
    uint256 public presaleCounter;

    // Events
    event PresaleCreated(uint256 id, uint256 tokenAmount, uint256 tokenPrice);
    event PresaleUpdated(uint256 id, uint256 tokenAmount, uint256 tokenPrice);
    event PresaleDeleted(uint256 id);
    event PresalePaused(uint256 id);
    event PresaleResumed(uint256 id);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Contract deployer is the default admin
        _grantRole(ADMIN_ROLE, msg.sender); // Contract deployer is also an admin
    }

    // Modifier to restrict access to only admins
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    // Function to add a new admin
    function addAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    // Function to remove an admin
    function removeAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }

    // Create a new presale
    function createPresale(uint256 _tokenAmount, uint256 _tokenPrice) external onlyAdmin {
        require(_tokenAmount > 0, "Token amount must be greater than 0.");
        require(_tokenPrice > 0, "Token price must be greater than 0.");

        // Increment presale counter
        presaleCounter++;

        // Create new presale
        presales[presaleCounter] = DataTypes.Presale({
            id: presaleCounter,
            tokenAmount: _tokenAmount,
            tokensSold: 0,
            tokenPrice: _tokenPrice,
            totalRaised: 0,
            isActive: true
        });

        emit PresaleCreated(presaleCounter, _tokenAmount, _tokenPrice);
    }

    // Read a presale
    function getPresale(uint256 _presaleId) external view returns (DataTypes.Presale memory) {
        require(presales[_presaleId].id != 0, "Presale does not exist.");
        return presales[_presaleId];
    }

    // Update a presale
    function updatePresale(uint256 _presaleId, uint256 _tokenAmount, uint256 _tokenPrice, uint256 _totalRaised) external onlyAdmin {
        require(presales[_presaleId].id != 0, "Presale does not exist.");
        require(_tokenAmount > 0, "Token amount must be greater than 0.");
        require(_tokenPrice > 0, "Token price must be greater than 0.");

        // Update presale details
        presales[_presaleId].tokenAmount = _tokenAmount;
        presales[_presaleId].tokenPrice = _tokenPrice;
        presales[_presaleId].totalRaised = _totalRaised;

        emit PresaleUpdated(_presaleId, _tokenAmount, _tokenPrice);
    }

    // Delete a presale
    function deletePresale(uint256 _presaleId) external onlyAdmin {
        require(presales[_presaleId].id != 0, "Presale does not exist.");

        // Delete the presale
        delete presales[_presaleId];

        emit PresaleDeleted(_presaleId);
    }

    // Pause a presale
    function pausePresale(uint256 _presaleId) external onlyAdmin {
        require(presales[_presaleId].id != 0, "Presale does not exist.");
        require(presales[_presaleId].isActive, "Presale is already paused.");

        presales[_presaleId].isActive = false;
        emit PresalePaused(_presaleId);
    }

    // Resume a presale
    function resumePresale(uint256 _presaleId) external onlyAdmin {
        require(presales[_presaleId].id != 0, "Presale does not exist.");
        require(!presales[_presaleId].isActive, "Presale is already active.");

        presales[_presaleId].isActive = true;
        emit PresaleResumed(_presaleId);
    }
}
