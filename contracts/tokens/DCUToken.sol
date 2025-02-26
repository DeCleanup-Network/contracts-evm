// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DCUToken is ERC20, Ownable {
    constructor() ERC20("DCU Token", "DCU") Ownable(msg.sender) {
        // Initial supply can be minted here if needed
    }

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}