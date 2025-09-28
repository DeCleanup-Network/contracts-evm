// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VerifierStaking.sol";

/**
 * @title VerifierRegistry
 * @dev Manages the registry of authorized verifiers for PoI verification
 * Integrates with VerifierStaking to check staking status
 */
contract VerifierRegistry is Ownable {
    // State variables
    VerifierStaking public verifierStaking;
    mapping(address => bool) private additionalVerifiers;

    // Events
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event VerifierStakingUpdated(address indexed oldContract, address indexed newContract);

    // Custom errors
    error REGISTRY__InvalidAddress();
    error REGISTRY__InvalidVerifierStaking();
    error REGISTRY__AlreadyVerifier();
    error REGISTRY__NotVerifier();

    /**
     * @dev Constructor to initialize the registry with the VerifierStaking contract
     * @param _verifierStaking Address of the VerifierStaking contract
     */
    constructor(address _verifierStaking) Ownable(msg.sender) {
        if (_verifierStaking == address(0)) revert REGISTRY__InvalidVerifierStaking();
        verifierStaking = VerifierStaking(_verifierStaking);
    }

    /**
     * @dev Modifier to restrict function access to only verified verifiers
     */
    modifier onlyVerifier() {
        if (!isVerifier(msg.sender)) revert REGISTRY__NotVerifier();
        _;
    }

    /**
     * @dev Checks if an address is an authorized verifier
     * @param user Address to check
     * @return bool True if the address is an authorized verifier
     */
    function isVerifier(address user) public view returns (bool) {
        if (user == address(0)) revert REGISTRY__InvalidAddress();
        return verifierStaking.isVerifier(user) || additionalVerifiers[user];
    }

    /**
     * @dev Adds an address as an additional verifier (for internal/trusted verifiers)
     * @param verifier Address to add as a verifier
     */
    function addVerifier(address verifier) external onlyOwner {
        if (verifier == address(0)) revert REGISTRY__InvalidAddress();
        if (additionalVerifiers[verifier]) revert REGISTRY__AlreadyVerifier();
        
        additionalVerifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    /**
     * @dev Removes an address from additional verifiers
     * @param verifier Address to remove
     */
    function removeVerifier(address verifier) external onlyOwner {
        if (verifier == address(0)) revert REGISTRY__InvalidAddress();
        if (!additionalVerifiers[verifier]) revert REGISTRY__NotVerifier();
        
        additionalVerifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }

    /**
     * @dev Updates the VerifierStaking contract address
     * @param _newVerifierStaking New VerifierStaking contract address
     */
    function updateVerifierStaking(address _newVerifierStaking) external onlyOwner {
        if (_newVerifierStaking == address(0)) revert REGISTRY__InvalidVerifierStaking();
        
        address oldContract = address(verifierStaking);
        verifierStaking = VerifierStaking(_newVerifierStaking);
        emit VerifierStakingUpdated(oldContract, _newVerifierStaking);
    }

    /**
     * @dev Checks if an address is an additional verifier (not through staking)
     * @param verifier Address to check
     * @return bool True if the address is an additional verifier
     */
    function isAdditionalVerifier(address verifier) external view returns (bool) {
        return additionalVerifiers[verifier];
    }
} 