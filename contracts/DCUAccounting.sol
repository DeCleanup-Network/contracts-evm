// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";

/**
 * @title DCUAccounting
 * @dev Contract for managing DCU token deposits and withdrawals with TGE restrictions
 */
contract DCUAccounting is Ownable {
    // Reference to the DCU token contract
    IDCUToken public dcuToken;
    
    // Mapping from user address to their DCU balance
    mapping(address => uint256) public balances;
    
    // Total amount of DCU tokens held by this contract
    uint256 public totalDeposits;
    
    // TGE status
    bool public tgeCompleted;
    
    // Whitelist for addresses that can transfer tokens before TGE
    mapping(address => bool) public whitelisted;
    
    // Mutex for reentrancy protection
    bool private _locked;
    
    // Events
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event TGEStatusChanged(bool completed);
    
    // Consolidated events for better tracking
    event DCUDeposit(
        address indexed user,
        uint256 amount,
        uint256 newBalance,
        uint256 timestamp
    );
    
    event DCUWithdrawal(
        address indexed user,
        uint256 amount,
        uint256 newBalance,
        uint256 timestamp
    );
    
    event DCUInternalTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fromNewBalance,
        uint256 toNewBalance,
        uint256 timestamp
    );
    
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
     * @dev Modifier to check if transfers are allowed
     * @param account The account to check
     */
    modifier canTransfer(address account) {
        require(tgeCompleted || whitelisted[account], "Transfers not allowed before TGE");
        _;
    }
    
    /**
     * @dev Constructor sets the DCU token address
     * @param _dcuToken Address of the DCU token contract
     */
    constructor(address _dcuToken) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
        _locked = false;
        tgeCompleted = false;
        
        // Whitelist the contract itself
        whitelisted[address(this)] = true;
        // Whitelist the owner (treasury)
        whitelisted[msg.sender] = true;
    }
    
    /**
     * @dev Set the TGE status
     * @param _tgeCompleted Whether the TGE is completed
     */
    function setTGEStatus(bool _tgeCompleted) external onlyOwner {
        tgeCompleted = _tgeCompleted;
        emit TGEStatusChanged(_tgeCompleted);
    }
    
    /**
     * @dev Add an address to the whitelist
     * @param account The address to whitelist
     */
    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        whitelisted[account] = true;
        emit AddressWhitelisted(account);
    }
    
    /**
     * @dev Remove an address from the whitelist
     * @param account The address to remove
     */
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelisted[account], "Address not whitelisted");
        whitelisted[account] = false;
        emit AddressRemovedFromWhitelist(account);
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
        
        // Emit consolidated deposit event
        emit DCUDeposit(
            msg.sender,
            amount,
            balances[msg.sender],
            block.timestamp
        );
    }
    
    /**
     * @dev Allows a user to withdraw their deposited DCU tokens
     * @param amount Amount of DCU to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant canTransfer(msg.sender) {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        require(dcuToken.transfer(msg.sender, amount), "Transfer failed");
        
        // Emit consolidated withdrawal event
        emit DCUWithdrawal(
            msg.sender,
            amount,
            balances[msg.sender],
            block.timestamp
        );
    }
    
    /**
     * @dev Transfer tokens internally between accounts (no actual token transfer)
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function internalTransfer(address to, uint256 amount) external nonReentrant {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // Emit consolidated internal transfer event
        emit DCUInternalTransfer(
            msg.sender,
            to,
            amount,
            balances[msg.sender],
            balances[to],
            block.timestamp
        );
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
        
        // Emit consolidated deposit event
        emit DCUDeposit(
            user,
            amount,
            balances[user],
            block.timestamp
        );
    }
    
    /**
     * @dev Allows the owner to withdraw DCU tokens on behalf of a user
     * @param user Address of the user
     * @param amount Amount of DCU to withdraw
     */
    function withdrawFor(address user, uint256 amount) external onlyOwner nonReentrant canTransfer(user) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[user] >= amount, "Insufficient balance");
        
        balances[user] -= amount;
        totalDeposits -= amount;
        
        require(dcuToken.transfer(user, amount), "Transfer failed");
        
        // Emit consolidated withdrawal event
        emit DCUWithdrawal(
            user,
            amount,
            balances[user],
            block.timestamp
        );
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
    
    /**
     * @dev Check if an address is whitelisted
     * @param account The address to check
     * @return Whether the address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }
} 