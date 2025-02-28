import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";
import { time } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";

describe("DCURewardManager", function () {
  async function deployContractsFixture() {
    const [owner, user1, user2, user3] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy DCU token
    const dcuToken = await hre.viem.deployContract("DCUToken");

    // Deploy DCURewardManager
    const dcuRewardManager = await hre.viem.deployContract("DCURewardManager", [
      dcuToken.address,
    ]);

    // Grant minting rights to DCURewardManager
    await dcuToken.write.transferOwnership([dcuRewardManager.address]);

    return {
      dcuToken,
      dcuRewardManager,
      owner,
      user1,
      user2,
      user3,
      publicClient,
    };
  }

  describe("Impact Product Claim Rewards", function () {
    it("Should not reward if PoI is not verified", async function () {
      const { dcuRewardManager, user1, owner } = await loadFixture(
        deployContractsFixture
      );

      // Try to reward Impact Product claim without PoI verification
      await expect(
        dcuRewardManager.write.rewardImpactProductClaim(
          [getAddress(user1.account.address), 1n],
          { account: owner.account }
        )
      ).to.be.rejectedWith("PoI not verified");
    });

    it("Should reward for Impact Product claim after PoI verification", async function () {
      const { dcuRewardManager, user1, owner } = await loadFixture(
        deployContractsFixture
      );

      // Verify PoI
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Reward Impact Product claim
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user1.account.address), 1n],
        { account: owner.account }
      );

      // Check balance
      const balance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(10n * 10n ** 18n); // 10 DCU
    });

    it("Should prevent duplicate rewards for the same level", async function () {
      const { dcuRewardManager, user1, owner } = await loadFixture(
        deployContractsFixture
      );

      // Verify PoI
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Reward Impact Product claim
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user1.account.address), 1n],
        { account: owner.account }
      );

      // Try to reward the same level again
      await expect(
        dcuRewardManager.write.rewardImpactProductClaim(
          [getAddress(user1.account.address), 1n],
          { account: owner.account }
        )
      ).to.be.rejectedWith("Level already claimed");

      // But can claim a different level
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user1.account.address), 2n],
        { account: owner.account }
      );

      // Check balance (should be 20 DCU now)
      const balance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(20n * 10n ** 18n); // 20 DCU
    });
  });

  describe("PoI Streak Rewards", function () {
    it("Should not reward streak for first PoI verification", async function () {
      const { dcuRewardManager, user1, owner } = await loadFixture(
        deployContractsFixture
      );

      // Verify PoI for the first time
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Check balance (should be 0 as no streak yet)
      const balance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(0n);
    });

    it("Should reward streak for PoI verification within 7 days", async function () {
      const { dcuRewardManager, user1, owner, publicClient } =
        await loadFixture(deployContractsFixture);

      // Verify PoI for the first time
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Advance time by 6 days
      await time.increase(6 * 24 * 60 * 60);

      // Verify PoI again
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Check balance (should be 3 DCU for streak)
      const balance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(3n * 10n ** 18n); // 3 DCU
    });

    it("Should not reward streak for PoI verification after 7 days", async function () {
      const { dcuRewardManager, user1, owner, publicClient } =
        await loadFixture(deployContractsFixture);

      // Verify PoI for the first time
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Advance time by 8 days
      await time.increase(8 * 24 * 60 * 60);

      // Verify PoI again
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Check balance (should be 0 as streak was broken)
      const balance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(0n);
    });
  });

  describe("Referral Rewards", function () {
    it("Should register referral relationship", async function () {
      const { dcuRewardManager, user1, user2, owner } = await loadFixture(
        deployContractsFixture
      );

      // Register referral
      await dcuRewardManager.write.registerReferral(
        [getAddress(user2.account.address), getAddress(user1.account.address)],
        { account: owner.account }
      );

      // Check referrer
      const referrer = await dcuRewardManager.read.getReferrer([
        getAddress(user2.account.address),
      ]);
      expect(referrer).to.equal(getAddress(user1.account.address));
    });

    it("Should reward referrer when invitee claims Impact Product", async function () {
      const { dcuRewardManager, user1, user2, owner } = await loadFixture(
        deployContractsFixture
      );

      // Register referral (user1 refers user2)
      await dcuRewardManager.write.registerReferral(
        [getAddress(user2.account.address), getAddress(user1.account.address)],
        { account: owner.account }
      );

      // Verify user2's PoI
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user2.account.address), true],
        { account: owner.account }
      );

      // User2 claims Impact Product
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user2.account.address), 1n],
        { account: owner.account }
      );

      // Check user1's balance (should be 1 DCU for referral)
      const referrerBalance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(referrerBalance).to.equal(1n * 10n ** 18n); // 1 DCU

      // Check user2's balance (should be 10 DCU for Impact Product claim)
      const inviteeBalance = await dcuRewardManager.read.getBalance([
        getAddress(user2.account.address),
      ]);
      expect(inviteeBalance).to.equal(10n * 10n ** 18n); // 10 DCU
    });

    it("Should only reward referrer once per invitee", async function () {
      const { dcuRewardManager, user1, user2, owner } = await loadFixture(
        deployContractsFixture
      );

      // Register referral (user1 refers user2)
      await dcuRewardManager.write.registerReferral(
        [getAddress(user2.account.address), getAddress(user1.account.address)],
        { account: owner.account }
      );

      // Verify user2's PoI
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user2.account.address), true],
        { account: owner.account }
      );

      // User2 claims first Impact Product
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user2.account.address), 1n],
        { account: owner.account }
      );

      // User2 claims second Impact Product
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user2.account.address), 2n],
        { account: owner.account }
      );

      // Check user1's balance (should still be 1 DCU for referral)
      const referrerBalance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(referrerBalance).to.equal(1n * 10n ** 18n); // 1 DCU

      // Check user2's balance (should be 20 DCU for two Impact Product claims)
      const inviteeBalance = await dcuRewardManager.read.getBalance([
        getAddress(user2.account.address),
      ]);
      expect(inviteeBalance).to.equal(20n * 10n ** 18n); // 20 DCU
    });
  });

  describe("Reward Claiming", function () {
    it("Should allow users to claim their rewards", async function () {
      const { dcuRewardManager, dcuToken, user1, owner } = await loadFixture(
        deployContractsFixture
      );

      // Verify PoI
      await dcuRewardManager.write.setPoiVerificationStatus(
        [getAddress(user1.account.address), true],
        { account: owner.account }
      );

      // Reward Impact Product claim
      await dcuRewardManager.write.rewardImpactProductClaim(
        [getAddress(user1.account.address), 1n],
        { account: owner.account }
      );

      // Claim rewards
      await dcuRewardManager.write.claimRewards(
        [
          10n * 10n ** 18n, // 10 DCU
        ],
        { account: user1.account }
      );

      // Check DCU token balance
      const tokenBalance = await dcuToken.read.balanceOf([
        getAddress(user1.account.address),
      ]);
      expect(tokenBalance).to.equal(10n * 10n ** 18n); // 10 DCU

      // Check internal balance (should be 0 after claiming)
      const internalBalance = await dcuRewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(internalBalance).to.equal(0n);
    });
  });
});
