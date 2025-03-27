// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DCUToken is ERC20, Ownable {
    // Custom errors
    error TOKEN__InvalidRewardLogicAddress(address invalidAddress);
    error TOKEN__OnlyRewardLogicCanMint(address caller, address rewardLogic);
    error TOKEN__MaxSupplyReached(uint256 attemptedSupply, uint256 maxSupply);

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
    
    address public rewardLogicContract;
    uint256 public immutable maxSupply;
    
    constructor(address _rewardLogicContract, uint256 _maxSupply) ERC20("DCU Token", "DCU") Ownable(msg.sender) {
        // Initial supply can be minted here if needed
        if (_rewardLogicContract == address(0)) revert TOKEN__InvalidRewardLogicAddress(_rewardLogicContract);
        rewardLogicContract = _rewardLogicContract;
        maxSupply = _maxSupply;
    }
    
    // Modifier to restrict minting to only RewardLogic contract
    modifier onlyRewardLogic() {
        if (msg.sender != rewardLogicContract) 
            revert TOKEN__OnlyRewardLogicCanMint(msg.sender, rewardLogicContract);
        _;
    }
    
    /**
     * @dev Update the reward logic contract address
     * @param _newRewardLogicContract The new reward logic contract address
     */
    function updateRewardLogicContract(address _newRewardLogicContract) external onlyOwner {
        if (_newRewardLogicContract == address(0)) 
            revert TOKEN__InvalidRewardLogicAddress(_newRewardLogicContract);
            
        address oldRewardLogic = rewardLogicContract;
        rewardLogicContract = _newRewardLogicContract;
        emit RewardLogicContractUpdated(oldRewardLogic, _newRewardLogicContract, block.timestamp);
    }

    function mint(address to, uint256 amount) external onlyRewardLogic returns (bool) {
        if (totalSupply() + amount > maxSupply) 
            revert TOKEN__MaxSupplyReached(totalSupply() + amount, maxSupply);
            
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
}