// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DCUStorage
 * @dev Contract for storing DCU tokens with ERC-20 compatibility, claim restrictions before TGE,
 * and preparation for future governance, staking, and locking integration.
 */
contract DCUStorage is ERC20, ERC20Burnable, Ownable, AccessControl, ReentrancyGuard {
    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    
    // TGE status
    bool public tgeCompleted;
    
    // Mapping from user address to their claimable DCU balance
    mapping(address => uint256) public claimableBalances;
    
    // Total amount of claimable DCU tokens
    uint256 public totalClaimable;
    
    // Staking and locking related mappings
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lockedBalances;
    mapping(address => uint256) public lockReleaseTime;
    
    // Whitelist for addresses that can transfer tokens before TGE
    mapping(address => bool) public whitelisted;
    
    // Events
    event ClaimableBalanceAdded(address indexed user, uint256 amount, uint256 newBalance);
    event TokensClaimed(address indexed user, uint256 amount, uint256 remainingClaimable);
    event TGEStatusChanged(bool completed);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event TokensStaked(address indexed user, uint256 amount, uint256 newStakedBalance);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 newStakedBalance);
    event TokensLocked(address indexed user, uint256 amount, uint256 releaseTime);
    event TokensUnlocked(address indexed user, uint256 amount);
    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    
    /**
     * @dev Modifier to check if transfers are allowed
     * @param account The account to check
     */
    modifier canTransfer(address account) {
        require(tgeCompleted || whitelisted[account], "Transfers not allowed before TGE");
        _;
    }
    
    /**
     * @dev Constructor sets up the token and roles
     */
    constructor() ERC20("DCU Token", "DCU") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
        
        // Whitelist the contract itself and the owner
        whitelisted[address(this)] = true;
        whitelisted[msg.sender] = true;
        
        tgeCompleted = false;
    }
    
    /**
     * @dev Set the TGE status
     * @param _tgeCompleted Whether the TGE is completed
     */
    function setTGEStatus(bool _tgeCompleted) external onlyRole(GOVERNANCE_ROLE) {
        tgeCompleted = _tgeCompleted;
        emit TGEStatusChanged(_tgeCompleted);
    }
    
    /**
     * @dev Add an address to the whitelist
     * @param account The address to whitelist
     */
    function addToWhitelist(address account) external onlyRole(GOVERNANCE_ROLE) {
        require(account != address(0), "Invalid address");
        whitelisted[account] = true;
        emit AddressWhitelisted(account);
    }
    
    /**
     * @dev Remove an address from the whitelist
     * @param account The address to remove
     */
    function removeFromWhitelist(address account) external onlyRole(GOVERNANCE_ROLE) {
        require(whitelisted[account], "Address not whitelisted");
        whitelisted[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }
    
    /**
     * @dev Add claimable balance for a user
     * @param user Address of the user
     * @param amount Amount to add to claimable balance
     */
    function addClaimableBalance(address user, uint256 amount) external onlyRole(REWARD_MANAGER_ROLE) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        claimableBalances[user] += amount;
        totalClaimable += amount;
        
        emit ClaimableBalanceAdded(user, amount, claimableBalances[user]);
    }
    
    /**
     * @dev Claim tokens from claimable balance
     * @param amount Amount to claim
     */
    function claimTokens(uint256 amount) external nonReentrant canTransfer(msg.sender) {
        require(amount > 0, "Amount must be greater than 0");
        require(claimableBalances[msg.sender] >= amount, "Insufficient claimable balance");
        
        claimableBalances[msg.sender] -= amount;
        totalClaimable -= amount;
        
        _mint(msg.sender, amount);
        
        emit TokensClaimed(msg.sender, amount, claimableBalances[msg.sender]);
    }
    
    /**
     * @dev Claim tokens on behalf of a user (for authorized roles)
     * @param user Address of the user
     * @param amount Amount to claim
     */
    function claimTokensFor(address user, uint256 amount) external nonReentrant onlyRole(GOVERNANCE_ROLE) canTransfer(user) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(claimableBalances[user] >= amount, "Insufficient claimable balance");
        
        claimableBalances[user] -= amount;
        totalClaimable -= amount;
        
        _mint(user, amount);
        
        emit TokensClaimed(user, amount, claimableBalances[user]);
    }
    
    /**
     * @dev Mint tokens (only for minter role)
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }
    
    /**
     * @dev Burn tokens from a specific address (only for governance role)
     * @param from Address to burn tokens from
     * @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount) public override onlyRole(GOVERNANCE_ROLE) {
        _burn(from, amount);
    }
    
    /**
     * @dev Override transfer function to enforce TGE restrictions
     * @param to Recipient address
     * @param value Amount to transfer
     */
    function transfer(address to, uint256 value) public override canTransfer(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }
    
    /**
     * @dev Override transferFrom function to enforce TGE restrictions
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount to transfer
     */
    function transferFrom(address from, address to, uint256 value) public override canTransfer(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
    /**
     * @dev Stake tokens (preparation for future staking integration)
     * @param amount Amount to stake
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _transfer(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        
        emit TokensStaked(msg.sender, amount, stakedBalances[msg.sender]);
    }
    
    /**
     * @dev Unstake tokens (preparation for future staking integration)
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        
        stakedBalances[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
        
        emit TokensUnstaked(msg.sender, amount, stakedBalances[msg.sender]);
    }
    
    /**
     * @dev Lock tokens for a period (preparation for future locking integration)
     * @param amount Amount to lock
     * @param lockDuration Duration in seconds to lock tokens
     */
    function lockTokens(uint256 amount, uint256 lockDuration) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(lockDuration > 0, "Lock duration must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        uint256 releaseTime = block.timestamp + lockDuration;
        
        _transfer(msg.sender, address(this), amount);
        lockedBalances[msg.sender] += amount;
        lockReleaseTime[msg.sender] = releaseTime;
        
        emit TokensLocked(msg.sender, amount, releaseTime);
    }
    
    /**
     * @dev Unlock tokens after lock period
     */
    function unlockTokens() external nonReentrant {
        require(lockedBalances[msg.sender] > 0, "No locked tokens");
        require(block.timestamp >= lockReleaseTime[msg.sender], "Tokens still locked");
        
        uint256 amount = lockedBalances[msg.sender];
        lockedBalances[msg.sender] = 0;
        
        _transfer(address(this), msg.sender, amount);
        
        emit TokensUnlocked(msg.sender, amount);
    }
    
    /**
     * @dev Get the claimable balance of a user
     * @param user Address of the user
     * @return The user's claimable DCU balance
     */
    function getClaimableBalance(address user) external view returns (uint256) {
        return claimableBalances[user];
    }
    
    /**
     * @dev Get the staked balance of a user
     * @param user Address of the user
     * @return The user's staked DCU balance
     */
    function getStakedBalance(address user) external view returns (uint256) {
        return stakedBalances[user];
    }
    
    /**
     * @dev Get the locked balance of a user
     * @param user Address of the user
     * @return amount The user's locked DCU balance
     * @return releaseTime The time when the locked tokens can be released
     */
    function getLockedBalance(address user) external view returns (uint256 amount, uint256 releaseTime) {
        return (lockedBalances[user], lockReleaseTime[user]);
    }
    
    /**
     * @dev Check if an address is whitelisted
     * @param account The address to check
     * @return Whether the address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }
    
    /**
     * @dev Update governance address
     * @param newGovernance New governance address
     */
    function updateGovernance(address newGovernance) external onlyRole(GOVERNANCE_ROLE) {
        require(newGovernance != address(0), "Invalid governance address");
        
        address oldGovernance = msg.sender;
        _revokeRole(GOVERNANCE_ROLE, oldGovernance);
        _grantRole(GOVERNANCE_ROLE, newGovernance);
        
        emit GovernanceUpdated(oldGovernance, newGovernance);
    }
    
    /**
     * @dev Set staking contract address
     * @param stakingContract Address of the staking contract
     */
    function setStakingContract(address stakingContract) external onlyRole(GOVERNANCE_ROLE) {
        require(stakingContract != address(0), "Invalid staking contract address");
        _grantRole(STAKING_ROLE, stakingContract);
    }
    
    /**
     * @dev Set reward manager contract address
     * @param rewardManager Address of the reward manager contract
     */
    function setRewardManager(address rewardManager) external onlyRole(GOVERNANCE_ROLE) {
        require(rewardManager != address(0), "Invalid reward manager address");
        _grantRole(REWARD_MANAGER_ROLE, rewardManager);
    }
} 