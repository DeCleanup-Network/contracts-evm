import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

describe("Submission", function () {
  // Define a fixture for deploying the test environment
  async function deploySubmissionFixture() {
    const [owner, user, admin] = await ethers.getSigners();

    // Deploy DCU token with a mock reward logic
    const DCUToken = await ethers.getContractFactory("DCUToken");
    const dcuToken = await DCUToken.deploy(owner.address);

    // Deploy the real reward logic
    const RewardLogic = await ethers.getContractFactory("RewardLogic");
    const rewardLogic = await RewardLogic.deploy(
      dcuToken.address,
      ethers.constants.AddressZero
    );

    // Update reward logic in token
    await dcuToken.updateRewardLogicContract(rewardLogic.address);

    // Deploy submission contract
    const defaultRewardAmount = ethers.utils.parseEther("10"); // 10 DCU tokens
    const Submission = await ethers.getContractFactory("Submission");
    const submission = await Submission.deploy(
      dcuToken.address,
      rewardLogic.address,
      defaultRewardAmount
    );

    // Authorize the submission contract to distribute DCU tokens
    await rewardLogic.authorizeContract(submission.address);

    // Grant admin role to the admin account
    const ADMIN_ROLE = await submission.ADMIN_ROLE();
    await submission.grantRole(ADMIN_ROLE, admin.address);

    return { submission, dcuToken, rewardLogic, owner, user, admin };
  }

  describe("Submission Creation", function () {
    it("Should allow users to create submissions", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Create a sample URI for the submission data
      const dataURI = "ipfs://QmExample123456";

      // Create a submission
      const tx = await submission.connect(user).createSubmission(dataURI);
      await tx.wait();

      // Check submission count
      const count = await submission.submissionCount();
      expect(count.toNumber()).to.equal(1);

      // Verify the submission details
      const userSubmissions = await submission.getSubmissionsByUser(
        user.address
      );
      expect(userSubmissions.length).to.equal(1);
      expect(userSubmissions[0].toNumber()).to.equal(0); // First submission ID

      // Check submission details
      const details = await submission.getSubmissionDetails(0);
      expect(details.submitter).to.equal(user.address);
      expect(details.dataURI).to.equal(dataURI);
      expect(details.status).to.equal(0); // Pending status
    });

    it("Should reject submissions with empty data URI", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Attempt to create a submission with empty URI
      try {
        await submission.connect(user).createSubmission("");
        expect.fail("Should have reverted");
      } catch (error) {
        expect(error.message).to.include("SUBMISSION__InvalidSubmissionData");
      }
    });
  });

  describe("Submission Approval", function () {
    it("Should allow admins to approve submissions", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      const dataURI = "ipfs://QmExample123456";
      await submission.connect(user).createSubmission(dataURI);

      // Approve the submission
      await submission.connect(admin).approveSubmission(0);

      // Check submission status
      const details = await submission.getSubmissionDetails(0);
      expect(details.status).to.equal(1); // Approved status
      expect(details.approver).to.equal(admin.address);
      expect(details.rewarded).to.equal(true); // Should be automatically rewarded
    });

    it("Should reject approval requests from non-admins", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Create a submission
      const dataURI = "ipfs://QmExample123456";
      await submission.connect(user).createSubmission(dataURI);

      // Try to approve as a regular user (should fail)
      try {
        await submission.connect(user).approveSubmission(0);
        expect.fail("Should have reverted");
      } catch (error) {
        expect(error.message).to.include("AccessControl");
      }
    });

    it("Should prevent approving the same submission twice", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      const dataURI = "ipfs://QmExample123456";
      await submission.connect(user).createSubmission(dataURI);

      // Approve the submission
      await submission.connect(admin).approveSubmission(0);

      // Try to approve again (should fail)
      try {
        await submission.connect(admin).approveSubmission(0);
        expect.fail("Should have reverted");
      } catch (error) {
        expect(error.message).to.include("SUBMISSION__AlreadyApproved");
      }
    });
  });

  describe("Submission Rejection", function () {
    it("Should allow admins to reject submissions", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      const dataURI = "ipfs://QmExample123456";
      await submission.connect(user).createSubmission(dataURI);

      // Reject the submission
      await submission.connect(admin).rejectSubmission(0);

      // Check submission status
      const details = await submission.getSubmissionDetails(0);
      expect(details.status).to.equal(2); // Rejected status
      expect(details.approver).to.equal(admin.address);
      expect(details.rewarded).to.equal(false); // Should not be rewarded
    });

    it("Should prevent rejecting the same submission twice", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      const dataURI = "ipfs://QmExample123456";
      await submission.connect(user).createSubmission(dataURI);

      // Reject the submission
      await submission.connect(admin).rejectSubmission(0);

      // Try to reject again (should fail)
      try {
        await submission.connect(admin).rejectSubmission(0);
        expect.fail("Should have reverted");
      } catch (error) {
        expect(error.message).to.include("SUBMISSION__AlreadyRejected");
      }
    });
  });

  describe("Configuration Management", function () {
    it("Should allow admin to update the default reward amount", async function () {
      const { submission, owner } = await loadFixture(deploySubmissionFixture);

      // Initial default reward is set to 10 DCU
      const initialReward = await submission.defaultRewardAmount();
      expect(initialReward.toString()).to.equal(
        ethers.utils.parseEther("10").toString()
      );

      // Update the default reward
      const newReward = ethers.utils.parseEther("20");
      await submission.connect(owner).updateDefaultReward(newReward);

      // Verify update
      const updatedReward = await submission.defaultRewardAmount();
      expect(updatedReward.toString()).to.equal(newReward.toString());
    });

    it("Should allow owner to update the reward logic contract", async function () {
      const { submission, rewardLogic, owner } = await loadFixture(
        deploySubmissionFixture
      );

      // Check initial reward logic address
      expect(await submission.rewardLogic()).to.equal(rewardLogic.address);

      // Deploy a new mock reward logic
      const newMockAddress = owner.address; // Just using owner address as a mock
      await submission.connect(owner).updateRewardLogic(newMockAddress);

      // Verify update
      expect(await submission.rewardLogic()).to.equal(newMockAddress);
    });
  });

  describe("Batch Operations", function () {
    it("Should retrieve submission batches correctly", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Create multiple submissions
      for (let i = 0; i < 5; i++) {
        await submission.connect(user).createSubmission(`ipfs://QmExample${i}`);
      }

      // Get a batch of submissions
      const batch = await submission.getSubmissionBatch(1, 3);

      // Verify batch count and content
      expect(batch.length).to.equal(3);
      expect(batch[0].id.toNumber()).to.equal(1);
      expect(batch[1].id.toNumber()).to.equal(2);
      expect(batch[2].id.toNumber()).to.equal(3);

      // Check the dataURIs
      expect(batch[0].dataURI).to.equal("ipfs://QmExample1");
      expect(batch[1].dataURI).to.equal("ipfs://QmExample2");
      expect(batch[2].dataURI).to.equal("ipfs://QmExample3");
    });
  });
});
