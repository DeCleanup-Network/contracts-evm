import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("DCURewardManager", function () {
  async function deployRewardManagerFixture() {
    const [owner, user1, user2] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Define initial reward amounts
    const dipClaimReward = 10n * 10n ** 18n; // 10 DCU
    const referralReward = 5n * 10n ** 18n; // 5 DCU
    const streakReward = 2n * 10n ** 18n; // 2 DCU

    const dcuToken = await hre.viem.deployContract("DCUToken");
    const rewardManager = await hre.viem.deployContract("DCURewardManager", [
      dcuToken.address,
      dipClaimReward,
      referralReward,
      streakReward,
    ]);

    // Transfer ownership of DCU token to reward manager
    await dcuToken.write.transferOwnership([rewardManager.address], {
      account: owner.account,
    });

    return {
      dcuToken,
      rewardManager,
      owner,
      user1,
      user2,
      publicClient,
      dipClaimReward,
      referralReward,
      streakReward,
    };
  }

  describe("Initialization", function () {
    it("Should set initial reward values correctly", async function () {
      const { rewardManager, dipClaimReward, referralReward, streakReward } =
        await loadFixture(deployRewardManagerFixture);

      expect(await rewardManager.read.dipClaimReward()).to.equal(
        dipClaimReward
      );
      expect(await rewardManager.read.referralReward()).to.equal(
        referralReward
      );
      expect(await rewardManager.read.streakReward()).to.equal(streakReward);
    });
  });

  describe("Reward Distribution", function () {
    it("Should reward user for dIP claim", async function () {
      const { rewardManager, owner, user1, dipClaimReward } = await loadFixture(
        deployRewardManagerFixture
      );

      await rewardManager.write.rewardDipClaim(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const balance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(dipClaimReward);
    });

    it("Should reward user for referral", async function () {
      const { rewardManager, owner, user1, referralReward } = await loadFixture(
        deployRewardManagerFixture
      );

      await rewardManager.write.rewardReferral(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const balance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(referralReward);
    });

    it("Should reward user for streak", async function () {
      const { rewardManager, owner, user1, streakReward } = await loadFixture(
        deployRewardManagerFixture
      );

      await rewardManager.write.rewardStreak(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const balance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(streakReward);
    });

    it("Should reward user with custom amount", async function () {
      const { rewardManager, owner, user1 } = await loadFixture(
        deployRewardManagerFixture
      );

      const customAmount = 15n * 10n ** 18n; // 15 DCU
      await rewardManager.write.rewardCustom(
        [getAddress(user1.account.address), customAmount, "special_event"],
        { account: owner.account }
      );

      const balance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(customAmount);
    });

    it("Should accumulate rewards from multiple activities", async function () {
      const {
        rewardManager,
        owner,
        user1,
        dipClaimReward,
        referralReward,
        streakReward,
      } = await loadFixture(deployRewardManagerFixture);

      await rewardManager.write.rewardDipClaim(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );
      await rewardManager.write.rewardReferral(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );
      await rewardManager.write.rewardStreak(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const expectedBalance = dipClaimReward + referralReward + streakReward;
      const balance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      expect(balance).to.equal(expectedBalance);
    });
  });

  describe("Reward Claiming", function () {
    it("Should allow user to claim rewards", async function () {
      const {
        dcuToken,
        rewardManager,
        owner,
        user1,
        dipClaimReward,
        referralReward,
      } = await loadFixture(deployRewardManagerFixture);

      // Add rewards to user1
      await rewardManager.write.rewardDipClaim(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );
      await rewardManager.write.rewardReferral(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const initialBalance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      const claimAmount = 5n * 10n ** 18n; // 5 DCU

      await rewardManager.write.claimRewards([claimAmount], {
        account: user1.account,
      });

      // Check user balance in reward manager
      const newBalance = await rewardManager.read.getBalance([
        getAddress(user1.account.address),
      ]);
      const expectedNewBalance = (initialBalance as bigint) - claimAmount;
      expect(newBalance).to.equal(expectedNewBalance);

      // Check user DCU token balance
      const tokenBalance = await dcuToken.read.balanceOf([
        getAddress(user1.account.address),
      ]);
      expect(tokenBalance).to.equal(claimAmount);
    });

    it("Should revert if user tries to claim more than their balance", async function () {
      const { rewardManager, owner, user1, dipClaimReward } = await loadFixture(
        deployRewardManagerFixture
      );

      // Add some rewards to user1
      await rewardManager.write.rewardDipClaim(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const excessAmount = dipClaimReward * 2n; // More than the user has

      await expect(
        rewardManager.write.claimRewards([excessAmount], {
          account: user1.account,
        })
      ).to.be.rejectedWith("Insufficient balance");
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to update reward amounts", async function () {
      const { rewardManager, owner } = await loadFixture(
        deployRewardManagerFixture
      );

      const newDipReward = 20n * 10n ** 18n;
      const newReferralReward = 10n * 10n ** 18n;
      const newStreakReward = 5n * 10n ** 18n;

      await rewardManager.write.updateRewardAmounts(
        [newDipReward, newReferralReward, newStreakReward],
        { account: owner.account }
      );

      expect(await rewardManager.read.dipClaimReward()).to.equal(newDipReward);
      expect(await rewardManager.read.referralReward()).to.equal(
        newReferralReward
      );
      expect(await rewardManager.read.streakReward()).to.equal(newStreakReward);
    });

    it("Should prevent non-owners from updating reward amounts", async function () {
      const { rewardManager, user1 } = await loadFixture(
        deployRewardManagerFixture
      );

      await expect(
        rewardManager.write.updateRewardAmounts(
          [20n * 10n ** 18n, 10n * 10n ** 18n, 5n * 10n ** 18n],
          { account: user1.account }
        )
      ).to.be.rejected;
    });

    it("Should prevent non-owners from rewarding users", async function () {
      const { rewardManager, user1, user2 } = await loadFixture(
        deployRewardManagerFixture
      );

      await expect(
        rewardManager.write.rewardDipClaim(
          [getAddress(user2.account.address)],
          {
            account: user1.account,
          }
        )
      ).to.be.rejected;
    });
  });
});
