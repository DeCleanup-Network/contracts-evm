// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VerifierRegistry} from "./VerifierRegistry.sol";

/**
 * @title PoIVerificationManager
 * @dev Manages verification results for Proof of Impact (PoI) submissions
 * Integrates with VerifierRegistry to ensure only authorized verifiers can submit verifications
 */
contract PoIVerificationManager is Ownable, ReentrancyGuard {
    // Custom errors
    error POIVERIFICATION__InvalidVerifierRegistry(address invalidAddress);
    error POIVERIFICATION__InvalidPoiId(uint256 poiId);
    error POIVERIFICATION__NotAuthorizedVerifier(address verifier);
    error POIVERIFICATION__AlreadyVerified(uint256 poiId, address verifier);
    error POIVERIFICATION__InvalidStatus(VerificationStatus status);


    // State variables
    enum VerificationStatus {
        Pending,
        Approved,
        Rejected
    }

    struct VerificationResult {
        address verifier;           // Address of the verifier
        VerificationStatus status;  // Status of the verification
        uint256 timestamp;         // When the verification was submitted
        string reason;             // (This is optional) reason for rejection
    }

    VerifierRegistry public verifierRegistry;

    // Mapping from PoI ID to verification results
    mapping(uint256 => VerificationResult[]) public verificationResults;

    // Mapping to track if a verifier has already verified a specific PoI
    mapping(uint256 => mapping(address => bool)) public hasVerified;

    // Events
    event PoIVerified(
        uint256 indexed poiId,
        address indexed verifier,
        VerificationStatus status,
        uint256 timestamp,
        string reason
    );
    event VerifierRegistryUpdated(address indexed oldRegistry, address indexed newRegistry);


    constructor(address _verifierRegistry) Ownable(msg.sender) {
        if (_verifierRegistry == address(0)) revert POIVERIFICATION__InvalidVerifierRegistry(_verifierRegistry);
        verifierRegistry = VerifierRegistry(_verifierRegistry);
    }

    /**
     * @dev Submit a verification result for a PoI
     * @param poiId The ID of the PoI being verified
     * @param status The verification status (Approved/Rejected)
     * @param reason Optional reason string (mainly for rejections)
     */
    function submitVerification(
        uint256 poiId,
        VerificationStatus status,
        string calldata reason
    ) external nonReentrant {
        // Input validation
        if (poiId == 0) revert POIVERIFICATION__InvalidPoiId(poiId);
        if (status == VerificationStatus.Pending) revert POIVERIFICATION__InvalidStatus(status);
        if (!verifierRegistry.isVerifier(msg.sender)) revert POIVERIFICATION__NotAuthorizedVerifier(msg.sender);
        if (hasVerified[poiId][msg.sender]) revert POIVERIFICATION__AlreadyVerified(poiId, msg.sender);

        // Record verification
        verificationResults[poiId].push(
            VerificationResult({
                verifier: msg.sender,
                status: status,
                timestamp: block.timestamp,
                reason: reason
            })
        );

        // Mark verifier as having verified this PoI
        hasVerified[poiId][msg.sender] = true;

        // Emit event
        emit PoIVerified(
            poiId,
            msg.sender,
            status,
            block.timestamp,
            reason
        );
    }

    /**
     * @dev Get all verification results for a specific PoI
     * @param poiId The ID of the PoI
     * @return VerificationResult[] Array of verification results
     */
    function getVerificationResults(uint256 poiId) external view returns (VerificationResult[] memory) {
        return verificationResults[poiId];
    }

    /**
     * @dev Get the latest verification result for a specific PoI
     * @param poiId The ID of the PoI
     * @return VerificationResult Latest verification result (reverts if no verifications)
     */
    function getLatestVerification(uint256 poiId) external view returns (VerificationResult memory) {
        VerificationResult[] storage results = verificationResults[poiId];
        if (results.length == 0) revert POIVERIFICATION__InvalidPoiId(poiId);
        return results[results.length - 1];
    }

    /**
     * @dev Check if a PoI has been approved by any verifier
     * @param poiId The ID of the PoI
     * @return bool True if the PoI has been approved
     */
    function isPoIApproved(uint256 poiId) external view returns (bool) {
        VerificationResult[] storage results = verificationResults[poiId];
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].status == VerificationStatus.Approved) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get the number of verifications for a specific PoI
     * @param poiId The ID of the PoI
     * @return uint256 Number of verifications
     */
    function getVerificationCount(uint256 poiId) external view returns (uint256) {
        return verificationResults[poiId].length;
    }

    /**
     * @dev Updates the VerifierRegistry contract address
     * @param _newRegistry New VerifierRegistry contract address
     */
    function updateVerifierRegistry(address _newRegistry) external onlyOwner {
        if (_newRegistry == address(0)) revert POIVERIFICATION__InvalidVerifierRegistry(_newRegistry);

        address oldRegistry = address(verifierRegistry);
        verifierRegistry = VerifierRegistry(_newRegistry);
        emit VerifierRegistryUpdated(oldRegistry, _newRegistry);
    }
} 