// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IDCUToken.sol";
import "./interfaces/IRewards.sol";

/**
 * @title Submission
 * @dev Contract for handling form submissions from the DeCleanup dapp
 */
contract Submission is Ownable, ReentrancyGuard, AccessControl {
    // Custom Errors
    error SUBMISSION__InvalidAddress();
    error SUBMISSION__InvalidSubmissionData();
    error SUBMISSION__SubmissionNotFound(uint256 submissionId);
    error SUBMISSION__Unauthorized(address user);
    error SUBMISSION__AlreadyApproved(uint256 submissionId);
    error SUBMISSION__AlreadyRejected(uint256 submissionId);
    
    // Role definitions for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Submission status enum
    enum SubmissionStatus { Pending, Approved, Rejected }
    
    // Submission structure
    struct Submission {
        uint256 id;
        address submitter;
        string dataURI;        // IPFS URI or other storage reference to submission data
        uint256 timestamp;
        SubmissionStatus status;
        address approver;      // Admin who processed the submission
        uint256 processedTimestamp;
        bool rewarded;         // Whether a reward has been issued for this submission
    }
    
    // Reference to the DCU token contract for rewards
    IDCUToken public dcuToken;
    
    // Reference to the RewardLogic contract
    IRewards public rewardLogic;
    
    // Mapping from submission ID to Submission data
    mapping(uint256 => Submission) public submissions;
    
    // Mapping from user address to their submission IDs
    mapping(address => uint256[]) public userSubmissions;
    
    // Total number of submissions
    uint256 public submissionCount;
    
    // Default reward amount for approved submissions (in wei, 18 decimals)
    uint256 public defaultRewardAmount;
    
    // Events
    event SubmissionCreated(
        uint256 indexed submissionId,
        address indexed submitter,
        string dataURI,
        uint256 timestamp
    );
    
    event SubmissionApproved(
        uint256 indexed submissionId,
        address indexed approver,
        uint256 timestamp
    );
    
    event SubmissionRejected(
        uint256 indexed submissionId,
        address indexed approver,
        uint256 timestamp
    );
    
    event DefaultRewardUpdated(uint256 oldAmount, uint256 newAmount);
    
    /**
     * @dev Constructor sets up the contract with DCU token, RewardLogic, and roles
     * @param _dcuToken Address of the DCU token contract
     * @param _rewardLogic Address of the RewardLogic contract
     * @param _defaultRewardAmount Default reward amount for approved submissions
     */
    constructor(address _dcuToken, address _rewardLogic, uint256 _defaultRewardAmount) Ownable(msg.sender) {
        if (_dcuToken == address(0)) revert SUBMISSION__InvalidAddress();
        if (_rewardLogic == address(0)) revert SUBMISSION__InvalidAddress();
        
        dcuToken = IDCUToken(_dcuToken);
        rewardLogic = IRewards(_rewardLogic);
        defaultRewardAmount = _defaultRewardAmount;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev Create a new submission
     * @param dataURI IPFS URI or other storage reference to submission data
     * @return submissionId The ID of the created submission
     */
    function createSubmission(string calldata dataURI) external nonReentrant returns (uint256) {
        if (bytes(dataURI).length == 0) revert SUBMISSION__InvalidSubmissionData();
        
        uint256 submissionId = submissionCount;
        
        submissions[submissionId] = Submission({
            id: submissionId,
            submitter: msg.sender,
            dataURI: dataURI,
            timestamp: block.timestamp,
            status: SubmissionStatus.Pending,
            approver: address(0),
            processedTimestamp: 0,
            rewarded: false
        });
        
        userSubmissions[msg.sender].push(submissionId);
        submissionCount++;
        
        emit SubmissionCreated(submissionId, msg.sender, dataURI, block.timestamp);
        
        return submissionId;
    }
    
    /**
     * @dev Approve a submission (only for admins)
     * @param submissionId The ID of the submission to approve
     */
    function approveSubmission(
        uint256 submissionId
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (submissionId >= submissionCount) revert SUBMISSION__SubmissionNotFound(submissionId);
        
        Submission storage submission = submissions[submissionId];
        
        if (submission.status == SubmissionStatus.Approved) 
            revert SUBMISSION__AlreadyApproved(submissionId);
        
        submission.status = SubmissionStatus.Approved;
        submission.approver = msg.sender;
        submission.processedTimestamp = block.timestamp;
        
        emit SubmissionApproved(
            submissionId,
            msg.sender,
            block.timestamp
        );
        
        // Trigger reward through RewardLogic for approved submissions
        if (!submission.rewarded) {
            submission.rewarded = true;
            rewardLogic.distributeDCU(submission.submitter, defaultRewardAmount);
        }
    }
    
    /**
     * @dev Reject a submission (only for admins)
     * @param submissionId The ID of the submission to reject
     */
    function rejectSubmission(
        uint256 submissionId
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (submissionId >= submissionCount) revert SUBMISSION__SubmissionNotFound(submissionId);
        
        Submission storage submission = submissions[submissionId];
        
        if (submission.status == SubmissionStatus.Rejected) 
            revert SUBMISSION__AlreadyRejected(submissionId);
        
        submission.status = SubmissionStatus.Rejected;
        submission.approver = msg.sender;
        submission.processedTimestamp = block.timestamp;
        
        emit SubmissionRejected(
            submissionId,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @dev Update the default reward amount (only for admins)
     * @param newRewardAmount The new default reward amount
     */
    function updateDefaultReward(uint256 newRewardAmount) external onlyRole(ADMIN_ROLE) {
        uint256 oldAmount = defaultRewardAmount;
        defaultRewardAmount = newRewardAmount;
        
        emit DefaultRewardUpdated(oldAmount, newRewardAmount);
    }
    
    /**
     * @dev Update the RewardLogic contract address (only for owner)
     * @param _newRewardLogic The new RewardLogic contract address
     */
    function updateRewardLogic(address _newRewardLogic) external onlyOwner {
        if (_newRewardLogic == address(0)) revert SUBMISSION__InvalidAddress();
        rewardLogic = IRewards(_newRewardLogic);
    }
    
    /**
     * @dev Get all submissions for a user
     * @param user The address of the user
     * @return An array of submission IDs
     */
    function getSubmissionsByUser(address user) external view returns (uint256[] memory) {
        return userSubmissions[user];
    }
    
    /**
     * @dev Get the details of a submission
     * @param submissionId The ID of the submission
     * @return The submission details
     */
    function getSubmissionDetails(uint256 submissionId) external view returns (Submission memory) {
        if (submissionId >= submissionCount) revert SUBMISSION__SubmissionNotFound(submissionId);
        return submissions[submissionId];
    }
    
    /**
     * @dev Get a batch of submissions for pagination
     * @param startIndex The starting index
     * @param batchSize The number of submissions to return
     * @return Submission[] An array of submissions
     */
    function getSubmissionBatch(uint256 startIndex, uint256 batchSize) 
        external 
        view 
        returns (Submission[] memory) 
    {
        uint256 endIndex = startIndex + batchSize;
        
        // Ensure we don't go past the end of the submissions
        if (endIndex > submissionCount) {
            endIndex = submissionCount;
        }
        
        // Calculate actual batch size
        uint256 resultSize = endIndex - startIndex;
        Submission[] memory result = new Submission[](resultSize);
        
        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = submissions[startIndex + i];
        }
        
        return result;
    }
} 