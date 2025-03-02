// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDCUToken {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function addClaimableBalance(address user, uint256 amount) external;
    function claimTokens(uint256 amount) external;
    function claimTokensFor(address user, uint256 amount) external;
    function getClaimableBalance(address user) external view returns (uint256);
    function isWhitelisted(address account) external view returns (bool);
    function setTGEStatus(bool _tgeCompleted) external;
} 