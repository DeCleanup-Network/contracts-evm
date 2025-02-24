// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";

contract DCUAccounting is Ownable {
    IDCUToken public dcuToken;
    mapping(address => uint256) public balances;
    
    constructor(address _dcuToken) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
    }

    function deposit(uint256 amount) external {
        require(dcuToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(dcuToken.transfer(msg.sender, amount), "Transfer failed");
    }
} 