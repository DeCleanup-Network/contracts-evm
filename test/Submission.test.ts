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

    // Add the submission contract to authorized contracts in RewardLogic
    // We'll use a try-catch since the interface might be different
    try {
      // Try to use authorizeContract if it exists
      await rewardLogic.authorizeContract(submission.address);
    } catch (error) {
      console.log("Unable to authorize contract:", error);
      // If authorizeContract is not available, try an alternative method
      // This is a no-op in tests but can help with debugging
    }

    // Grant admin role to the admin account
    const ADMIN_ROLE = await submission.ADMIN_ROLE();
    await submission.grantRole(ADMIN_ROLE, admin.address);

    return { submission, dcuToken, rewardLogic, owner, user, admin };
  }

  describe("Submission Creation", function () {
    it("Should create a submission with the correct data", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Create a submission
      const dataURI = "ipfs://QmTest123";
      const tx = await submission.connect(user).createSubmission(dataURI);
      await tx.wait();

      // Get the submission ID from events (should be 0 for the first submission)
      const submissionId = 0;

      // Check submission count
      const count = await submission.submissionCount();
      expect(count.toNumber()).to.equal(1);

      // Verify the user's submission was recorded
      const userSubmissions = await submission.getSubmissionsByUser(
        user.address
      );
      expect(userSubmissions.length).to.equal(1);
      expect(userSubmissions[0].toNumber()).to.equal(submissionId);
    });

    it("Should reject submissions with empty dataURI", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Try to create a submission with empty data URI
      try {
        await submission.connect(user).createSubmission("");
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("SUBMISSION__InvalidSubmissionData");
      }
    });
  });

  describe("Submission Approval", function () {
    it("Should allow admin to approve a submission and make rewards claimable", async function () {
      const { submission, user, admin, dcuToken } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      const dataURI = "ipfs://QmTest123";
      await submission.connect(user).createSubmission(dataURI);
      const submissionId = 0;

      // Check initial claimable rewards
      const initialClaimable = await submission.getClaimableRewards(
        user.address
      );
      console.log("Initial claimable rewards:", initialClaimable.toString());
      expect(initialClaimable.toNumber()).to.equal(0);

      // Check user's initial DCU balance
      const initialBalance = await dcuToken.balanceOf(user.address);
      console.log("Initial DCU balance:", initialBalance.toString());
      expect(initialBalance.toNumber()).to.equal(0);

      // Admin approves the submission
      const tx = await submission
        .connect(admin)
        .approveSubmission(submissionId);
      await tx.wait();

      // Check that rewards are now claimable
      const claimableRewards = await submission.getClaimableRewards(
        user.address
      );
      console.log(
        "Claimable rewards after approval:",
        claimableRewards.toString()
      );
      const expectedReward = ethers.utils.parseEther("10");
      console.log("Expected reward amount:", expectedReward.toString());

      // Using strict equality can fail with BigNumber, use equals method instead
      expect(claimableRewards.toString()).to.equal(expectedReward.toString());

      // User's DCU balance should still be 0 until they claim the rewards
      const balanceAfterApproval = await dcuToken.balanceOf(user.address);
      console.log(
        "DCU balance after approval:",
        balanceAfterApproval.toString()
      );
      expect(balanceAfterApproval.toNumber()).to.equal(0);
    });

    it("Should prevent non-admin from approving submissions", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Create a submission
      await submission.connect(user).createSubmission("ipfs://QmTest123");
      const submissionId = 0;

      // Try to approve the submission as non-admin user
      try {
        await submission.connect(user).approveSubmission(submissionId);
        expect.fail("Should have reverted");
      } catch (error: any) {
        // Check for AccessControl error
        expect(error.message).to.include("AccessControl");
      }
    });

    it("Should prevent approving a non-existent submission", async function () {
      const { submission, admin } = await loadFixture(deploySubmissionFixture);

      // Try to approve a non-existent submission
      try {
        await submission.connect(admin).approveSubmission(999);
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("SUBMISSION__SubmissionNotFound");
      }
    });

    it("Should prevent approving an already approved submission", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create and approve a submission
      await submission.connect(user).createSubmission("ipfs://QmTest123");
      await submission.connect(admin).approveSubmission(0);

      // Try to approve it again
      try {
        await submission.connect(admin).approveSubmission(0);
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("SUBMISSION__AlreadyApproved");
      }
    });
  });

  describe("Reward Claiming", function () {
    it("Should allow users to claim rewards from approved submissions", async function () {
      const { submission, user, admin, dcuToken } = await loadFixture(
        deploySubmissionFixture
      );

      // Create and approve a submission
      await submission.connect(user).createSubmission("ipfs://QmTest123");
      await submission.connect(admin).approveSubmission(0);

      // Check claimable rewards before claiming
      const claimableBefore = await submission.getClaimableRewards(
        user.address
      );
      console.log("Claimable before claiming:", claimableBefore.toString());
      const expectedReward = ethers.utils.parseEther("10");
      console.log("Expected reward amount:", expectedReward.toString());

      // Using string comparison for BigNumber
      expect(claimableBefore.toString()).to.equal(expectedReward.toString());

      // Claim rewards
      await submission.connect(user).claimRewards();

      // Check claimable rewards after claiming (should be 0)
      const claimableAfter = await submission.getClaimableRewards(user.address);
      console.log("Claimable after claiming:", claimableAfter.toString());
      expect(claimableAfter.toNumber()).to.equal(0);

      // Check user's DCU balance after claiming
      const balanceAfterClaim = await dcuToken.balanceOf(user.address);
      console.log("DCU balance after claim:", balanceAfterClaim.toString());
      console.log("Expected DCU after claim:", expectedReward.toString());

      // Using string comparison for BigNumber
      expect(balanceAfterClaim.toString()).to.equal(expectedReward.toString());
    });

    it("Should prevent claiming when no rewards are available", async function () {
      const { submission, user } = await loadFixture(deploySubmissionFixture);

      // Try to claim rewards when none are available
      try {
        await submission.connect(user).claimRewards();
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("SUBMISSION__NoRewardsAvailable");
      }
    });

    it("Should accumulate rewards from multiple approved submissions", async function () {
      const { submission, user, admin, dcuToken } = await loadFixture(
        deploySubmissionFixture
      );

      // Create and approve first submission
      await submission.connect(user).createSubmission("ipfs://QmTest1");
      await submission.connect(admin).approveSubmission(0);

      // Create and approve second submission
      await submission.connect(user).createSubmission("ipfs://QmTest2");
      await submission.connect(admin).approveSubmission(1);

      // Check cumulative claimable rewards
      const totalClaimable = await submission.getClaimableRewards(user.address);
      console.log("Total claimable rewards:", totalClaimable.toString());
      const expectedTotal = ethers.utils.parseEther("20"); // 10 + 10 = 20 DCU
      console.log("Expected total rewards:", expectedTotal.toString());

      // Using string comparison for BigNumber
      expect(totalClaimable.toString()).to.equal(expectedTotal.toString());

      // Claim all rewards
      await submission.connect(user).claimRewards();

      // Verify user received all rewards
      const finalBalance = await dcuToken.balanceOf(user.address);
      console.log("Final DCU balance:", finalBalance.toString());

      // Using string comparison for BigNumber
      expect(finalBalance.toString()).to.equal(expectedTotal.toString());

      // Claimable amount should be reset to 0
      const claimableAfter = await submission.getClaimableRewards(user.address);
      console.log("Claimable after claiming all:", claimableAfter.toString());
      expect(claimableAfter.toNumber()).to.equal(0);
    });
  });

  describe("Submission Rejection", function () {
    it("Should allow admin to reject a submission", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create a submission
      await submission.connect(user).createSubmission("ipfs://QmTest123");
      const submissionId = 0;

      // Admin rejects the submission
      await submission.connect(admin).rejectSubmission(submissionId);

      // Check submission count
      const count = await submission.submissionCount();
      expect(count.toNumber()).to.equal(1);

      // Check that no rewards are claimable
      const claimableRewards = await submission.getClaimableRewards(
        user.address
      );
      expect(claimableRewards.toNumber()).to.equal(0);
    });

    it("Should prevent rejecting an already rejected submission", async function () {
      const { submission, user, admin } = await loadFixture(
        deploySubmissionFixture
      );

      // Create and reject a submission
      await submission.connect(user).createSubmission("ipfs://QmTest123");
      await submission.connect(admin).rejectSubmission(0);

      // Try to reject it again
      try {
        await submission.connect(admin).rejectSubmission(0);
        expect.fail("Should have reverted");
      } catch (error: any) {
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
      const { submission, rewardLogic, owner, dcuToken } = await loadFixture(
        deploySubmissionFixture
      );

      // Check initial reward logic address
      expect(await submission.rewardLogic()).to.equal(rewardLogic.address);

      // Deploy a new reward logic contract
      const NewRewardLogic = await ethers.getContractFactory("RewardLogic");
      const newRewardLogicContract = await NewRewardLogic.deploy(
        dcuToken.address,
        ethers.constants.AddressZero
      );

      // Update the reward logic contract
      await submission
        .connect(owner)
        .updateRewardLogic(newRewardLogicContract.address);

      // Verify update
      expect(await submission.rewardLogic()).to.equal(
        newRewardLogicContract.address
      );
    });

    it("Should reject invalid addresses for reward logic update", async function () {
      const { submission, owner } = await loadFixture(deploySubmissionFixture);

      // Try to update with zero address
      try {
        await submission
          .connect(owner)
          .updateRewardLogic(ethers.constants.AddressZero);
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("SUBMISSION__InvalidAddress");
      }
    });
  });
});
