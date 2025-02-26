// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DexStorage.sol";

contract DexManager is Ownable {
    // DexStorage contract
    DexStorage public dexStorage;

    // ERC20 token address
    address public tokenAddress;

    // Pause state
    bool public paused;

    // Events
    event TokensPurchased(uint256 id, address buyer, uint256 amount);
    event PresalePaused(uint256 id);
    event PresaleResumed(uint256 id);
    event TokensWithdrawn(address token, uint256 amount);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor(address _tokenAddress, address _dexStorageAddress) {
        tokenAddress = _tokenAddress;
        dexStorage = DexStorage(_dexStorageAddress);
    }

    // Buy tokens from a specific presale
function buyTokens(uint256 _presaleId, uint256 _amount) external payable whenNotPaused {
    // Get presale details from DexStorage
    DataTypes.Presale memory presale = dexStorage.getPresale(_presaleId);

    require(presale.isActive, "Presale is not active.");
    require(_amount > 0, "Amount must be greater than 0.");

    // Calculate the total cost in wei
    uint256 totalCostEth = _amount / 1 ether;

    uint256 totalCost = totalCostEth * presale.tokenPrice;

    // Convert totalCost to ETH

    // Ensure the user sent the correct amount of ETH/POL
    require(msg.value == totalCost, "Incorrect POL amount sent.");

    // Check if the contract has enough tokens to sell
    IERC20 token = IERC20(tokenAddress);
    require(token.balanceOf(address(this)) >= _amount, "Insufficient tokens in contract.");

    // Update presale state in DexStorage
    dexStorage.updatePresale(
        _presaleId,
        presale.tokenAmount,
        presale.tokenPrice
    );

    // Transfer tokens to the buyer
    token.transfer(msg.sender, _amount);

    emit TokensPurchased(_presaleId, msg.sender, _amount);
}



    // Pause a specific presale
    function pausePresale(uint256 _presaleId) external onlyOwner {
        DataTypes.Presale memory presale = dexStorage.getPresale(_presaleId);
        require(presale.isActive, "Presale is not active.");

        dexStorage.pausePresale(_presaleId);

        emit PresalePaused(_presaleId);
    }

    // Resume a specific presale
    function resumePresale(uint256 _presaleId) external onlyOwner {
        DataTypes.Presale memory presale = dexStorage.getPresale(_presaleId);
        require(!presale.isActive, "Presale is already active.");

        dexStorage.resumePresale(_presaleId);

        emit PresaleResumed(_presaleId);
    }

    // Withdraw accidentally sent ERC20 tokens
    function withdrawAccidentallySentTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient tokens in contract.");

        token.transfer(owner(), _amount);

        emit TokensWithdrawn(_tokenAddress, _amount);
    }

    // Withdraw POL raised from a specific presale
    function withdrawRaisedPOL(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    // Fallback function to receive POL
    receive() external payable {}
}