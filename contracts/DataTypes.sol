// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct Presale {
        uint256 id;             // Unique ID for the presale
        uint256 tokenAmount;    // Total tokens to be sold
        uint256 tokensSold;     // Tokens sold so far
        uint256 tokenPrice;     // Price per token in POL
        uint256 totalRaised;    // Total POL raised
        bool isActive;         // Whether the presale is active
    }
}