// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IRewards
 * @dev Interface for the rewards distribution contract
 */
interface IRewards {
    /**
     * @dev Distribute DCU tokens to a user
     * @param user The address of the user to distribute to
     * @param amount The amount to distribute
     */
    function distributeDCU(address user, uint256 amount) external;
} 