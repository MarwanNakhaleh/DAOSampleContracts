// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Token
/// @author Marwan Nakhaleh
contract Token is ERC20, Ownable {
    address payable private projectOwnerAddress;

    constructor(string memory name, string memory symbol, uint256 initialSupply) Ownable(msg.sender) ERC20(name, symbol) {
        require(bytes(name).length > 0, "Name must have content");
        require(bytes(symbol).length > 0, "Symbol must have content");
        require(initialSupply > 0, "Initial supply must be more than zero");
        projectOwnerAddress = payable(msg.sender);
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    /// @dev only the owner can mint tokens and mint them to a specific address
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}