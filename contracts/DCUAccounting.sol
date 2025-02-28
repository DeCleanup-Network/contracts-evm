// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";

/**
 * @title DCUAccounting
 * @dev Contract for managing DCU token deposits and withdrawals
 */
contract DCUAccounting is Ownable {
    // Reference to the DCU token contract
    IDCUToken public dcuToken;
    
    // Mapping from user address to their DCU balance
    mapping(address => uint256) public balances;
    
    // Total amount of DCU tokens held by this contract
    uint256 public totalDeposits;
    
    // Mutex for reentrancy protection
    bool private _locked;
    
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    /**
     * @dev Modifier to prevent reentrancy attacks
     */
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    
    /**
     * @dev Constructor sets the DCU token address
     * @param _dcuToken Address of the DCU token contract
     */
    constructor(address _dcuToken) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
        _locked = false;
    }
    
    /**
     * @dev Allows a user to deposit DCU tokens
     * @param amount Amount of DCU to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(dcuToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        balances[msg.sender] += amount;
        totalDeposits += amount;
        
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev Allows a user to withdraw their deposited DCU tokens
     * @param amount Amount of DCU to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        require(dcuToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev Get the DCU balance of a user
     * @param user Address of the user
     * @return The user's DCU balance
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev Allows the owner to deposit DCU tokens on behalf of a user
     * @param user Address of the user
     * @param amount Amount of DCU to deposit
     */
    function depositFor(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(dcuToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        balances[user] += amount;
        totalDeposits += amount;
        
        emit Deposit(user, amount);
    }
    
    /**
     * @dev Allows the owner to withdraw DCU tokens on behalf of a user
     * @param user Address of the user
     * @param amount Amount of DCU to withdraw
     */
    function withdrawFor(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[user] >= amount, "Insufficient balance");
        
        balances[user] -= amount;
        totalDeposits -= amount;
        
        require(dcuToken.transfer(user, amount), "Transfer failed");
        
        emit Withdrawal(user, amount);
    }
    
    /**
     * @dev Emergency function to withdraw all tokens (only owner)
     * @notice This should only be used in emergency situations
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 contractBalance = dcuToken.balanceOf(address(this));
        require(contractBalance > 0, "No tokens to withdraw");
        
        require(dcuToken.transfer(owner(), contractBalance), "Transfer failed");
        
        emit EmergencyWithdrawal(owner(), contractBalance);
    }
} 