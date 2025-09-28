// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDCUToken} from "./interfaces/IDCUToken.sol";

/**
 * @title VerifierStaking
 * @dev Manages staking of DCU tokens for verifier qualification
 * Implements stake tracking, minimum thresholds, and unstaking mechanics
 */
contract VerifierStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Custom errors
    error STAKE__InsufficientStakeAmount(uint256 provided, uint256 required);
    error STAKE__NoStakeFound(address staker);
    error STAKE__StakeAlreadyExists(address staker);
    error STAKE__UnstakingLocked(uint256 remainingTime);
    error STAKE__InvalidDCUToken(address token);
    error STAKE__InvalidAmount(uint256 amount);
    error STAKE__FailedToTransfer();

    // Constants
    uint256 public constant MINIMUM_STAKE = 1000 * 10**18; // 1,000 DCU with 18 decimals
    uint256 public constant UNSTAKING_DELAY = 7 days;

    // State variables
    IDCUToken public dcuToken;
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        bool isActive;
    }
    
    // Staker info mapping
    mapping(address => StakeInfo) public stakes;
    
    // Events
    event VerifierRegistered(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );
    
    event VerifierUnstaked(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );
    
    event StakeAmountUpdated(
        address indexed staker,
        uint256 oldAmount,
        uint256 newAmount,
        uint256 timestamp
    );

    /**
     * @dev Constructor sets the DCU token contract
     * @param _dcuToken Address of the DCU token contract
     */
    constructor(address _dcuToken) Ownable(msg.sender) {
        if (_dcuToken == address(0)) revert STAKE__InvalidDCUToken(_dcuToken);
        dcuToken = IDCUToken(_dcuToken);
    }

    /**
     * @dev Allows a user to stake DCU tokens to become a verifier
     * @param amount Amount of DCU to stake
     */
    function stakeDCU(uint256 amount) external nonReentrant {
        // Validate amount
        if (amount == 0) revert STAKE__InvalidAmount(amount);
        if (amount < MINIMUM_STAKE) {
            revert STAKE__InsufficientStakeAmount(amount, MINIMUM_STAKE);
        }

        // Check if staker already exists
        if (stakes[msg.sender].isActive) {
            revert STAKE__StakeAlreadyExists(msg.sender);
        }

        // Transfer tokens to this contract using SafeERC20
        IERC20(address(dcuToken)).safeTransferFrom(msg.sender, address(this), amount);

        // Record stake
        stakes[msg.sender] = StakeInfo({
            amount: amount,
            timestamp: block.timestamp,
            isActive: true
        });

        emit VerifierRegistered(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Allows a verifier to unstake their DCU tokens after delay period
     */
    function unstakeDCU() external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];

        // Validate stake exists
        if (!stakeInfo.isActive) {
            revert STAKE__NoStakeFound(msg.sender);
        }

        // Check unstaking delay
        if (block.timestamp < stakeInfo.timestamp + UNSTAKING_DELAY) {
            revert STAKE__UnstakingLocked(
                (stakeInfo.timestamp + UNSTAKING_DELAY) - block.timestamp
            );
        }

        uint256 amount = stakeInfo.amount;

        // Clear stake before transfer
        delete stakes[msg.sender];

        // Transfer tokens back to staker using SafeERC20
        IERC20(address(dcuToken)).safeTransfer(msg.sender, amount);

        emit VerifierUnstaked(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Allows increasing stake amount
     * @param additionalAmount Amount to add to existing stake
     */
    function increaseStake(uint256 additionalAmount) external nonReentrant {
        if (additionalAmount == 0) revert STAKE__InvalidAmount(additionalAmount);

        StakeInfo storage stakeInfo = stakes[msg.sender];
        if (!stakeInfo.isActive) {
            revert STAKE__NoStakeFound(msg.sender);
        }

        uint256 oldAmount = stakeInfo.amount;
        uint256 newAmount = oldAmount + additionalAmount;

        // Transfer additional tokens using SafeERC20
        IERC20(address(dcuToken)).safeTransferFrom(msg.sender, address(this), additionalAmount);

        // Update stake amount
        stakeInfo.amount = newAmount;

        emit StakeAmountUpdated(msg.sender, oldAmount, newAmount, block.timestamp);
    }

    /**
     * @dev Check if an address is a verifier
     * @param account Address to check
     * @return bool True if address is a verifier
     */
    function isVerifier(address account) external view returns (bool) {
        return stakes[account].isActive;
    }

    /**
     * @dev Get stake information for an address
     * @param account Address to query
     * @return amount Staked amount
     * @return timestamp Stake timestamp
     * @return isActive Whether stake is active
     */
    function getStakeInfo(address account) external view returns (
        uint256 amount,
        uint256 timestamp,
        bool isActive
    ) {
        StakeInfo memory stakeInfo = stakes[account];
        return (stakeInfo.amount, stakeInfo.timestamp, stakeInfo.isActive);
    }

    /**
     * @dev Emergency function to update DCU token address
     * @param _newDcuToken New DCU token address
     */
    function updateDCUToken(address _newDcuToken) external onlyOwner {
        if (_newDcuToken == address(0)) revert STAKE__InvalidDCUToken(_newDcuToken);
        dcuToken = IDCUToken(_newDcuToken);
    }
}