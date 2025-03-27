// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title DCUToken
 * @dev DeCleanup Utility Token with dynamic supply model and governance features
 * Implements ERC20 standard with additional features for tracking and compatibility
 */
contract DCUToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    // Events for detailed tracking
    event DCUMinted(
        address indexed to,
        uint256 amount,
        uint256 newBalance,
        uint256 timestamp
    );
    
    event DCUBurned(
        address indexed from,
        uint256 amount,
        uint256 newBalance,
        uint256 timestamp
    );
    
    event RewardLogicContractUpdated(
        address indexed oldRewardLogic,
        address indexed newRewardLogic,
        uint256 timestamp
    );
    
    event SupplyCapAdded(
        uint256 capAmount,
        uint256 timestamp,
        address indexed by
    );
    
    event SupplyCapRemoved(
        uint256 timestamp,
        address indexed by
    );
    
    // State variables
    address public rewardLogicContract;
    uint256 public totalMinted;
    uint256 public supplyCap;
    bool public supplyCapActive;
    
    // Additional ERC20 metadata
    uint8 private constant _decimals = 18;
    
    /**
     * @dev Constructor for DCUToken
     * @param _rewardLogicContract Address of the reward logic contract
     */
    constructor(address _rewardLogicContract) 
        ERC20("DeCleanup Utility Token", "DCU") 
        ERC20Permit("DeCleanup Utility Token")
        Ownable(msg.sender) 
    {
        require(_rewardLogicContract != address(0), "Invalid RewardLogic address");
        rewardLogicContract = _rewardLogicContract;
        supplyCapActive = false; // Start with no supply cap
    }
    
    /**
     * @dev Returns the number of decimals used for user representation
     * @return The number of decimals
     */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Modifier to restrict minting to only RewardLogic contract
     */
    modifier onlyRewardLogic() {
        require(msg.sender == rewardLogicContract, "Only RewardLogic Contract can mint");
        _;
    }
    
    /**
     * @dev Update the reward logic contract address
     * @param _newRewardLogicContract The new reward logic contract address
     */
    function updateRewardLogicContract(address _newRewardLogicContract) external onlyOwner {
        require(_newRewardLogicContract != address(0), "Invalid RewardLogic address");
        address oldRewardLogic = rewardLogicContract;
        rewardLogicContract = _newRewardLogicContract;
        emit RewardLogicContractUpdated(oldRewardLogic, _newRewardLogicContract, block.timestamp);
    }

    /**
     * @dev Mint new tokens - only callable by the RewardLogic contract
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     * @return success Whether the minting was successful
     */
    function mint(address to, uint256 amount) external onlyRewardLogic returns (bool) {
        // If a supply cap is active, enforce it
        if (supplyCapActive) {
            require(totalSupply() + amount <= supplyCap, "Supply cap would be exceeded");
        }
        
        // Track total minted supply for future reference
        totalMinted += amount;
        
        // Mint the tokens
        _mint(to, amount);
        
        // Emit detailed minting event
        emit DCUMinted(
            to,
            amount,
            balanceOf(to),
            block.timestamp
        );
        
        return true;
    }

    /**
     * @dev Burn tokens - only callable by owner
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        
        // Emit detailed burning event
        emit DCUBurned(
            from,
            amount,
            balanceOf(from),
            block.timestamp
        );
    }
    
    /**
     * @dev Set a cap on the total token supply (for future governance)
     * @param _supplyCap The maximum total supply
     */
    function setSupplyCap(uint256 _supplyCap) external onlyOwner {
        require(_supplyCap > totalSupply(), "Cap cannot be less than current supply");
        supplyCap = _supplyCap;
        supplyCapActive = true;
        
        emit SupplyCapAdded(_supplyCap, block.timestamp, msg.sender);
    }
    
    /**
     * @dev Remove the supply cap to allow unlimited minting
     */
    function removeSupplyCap() external onlyOwner {
        supplyCapActive = false;
        emit SupplyCapRemoved(block.timestamp, msg.sender);
    }
    
    /**
     * @dev Get total minted tokens (including burned ones)
     * @return The total amount of tokens ever minted
     */
    function getTotalMinted() external view returns (uint256) {
        return totalMinted;
    }
    
    /**
     * @dev Helper function to get the current circulation status
     * @return current The current total supply
     * @return minted The total amount of tokens ever minted
     * @return capActive Whether a supply cap is currently active
     * @return cap The current supply cap (only relevant if capActive is true)
     */
    function getCirculationStatus() external view returns (uint256 current, uint256 minted, bool capActive, uint256 cap) {
        return (totalSupply(), totalMinted, supplyCapActive, supplyCap);
    }
}