// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDCUToken {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
} 