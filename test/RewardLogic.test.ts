import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("RewardLogic", function () {
  async function deployContractsFixture() {
    const [owner, user] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    const dcuToken = await hre.viem.deployContract("DCUToken");
    const nftCollection = await hre.viem.deployContract("NFTCollection");

    const rewardLogic = await hre.viem.deployContract("RewardLogic", [
      dcuToken.address,
      nftCollection.address,
    ]);

    // Grant minting rights to RewardLogic
    await dcuToken.write.transferOwnership([rewardLogic.address]);
    // Grant minting rights to owner for NFTs
    await nftCollection.write.transferOwnership([owner.account.address]);

    return {
      dcuToken,
      nftCollection,
      rewardLogic,
      owner,
      user,
      publicClient,
    };
  }

  describe("Reward Calculation and Distribution", function () {
    it("Should calculate rewards correctly", async function () {
      const { rewardLogic, nftCollection, user, owner } = await loadFixture(
        deployContractsFixture
      );

      // Mint some NFTs to the user
      await nftCollection.write.mint([getAddress(user.account.address)], {
        account: owner.account,
      });
      await nftCollection.write.mint([getAddress(user.account.address)], {
        account: owner.account,
      });

      const reward = await rewardLogic.read.calculateReward([
        getAddress(user.account.address),
      ]);
      expect(reward).to.equal(200n * 10n ** 18n); // 2 NFTs * 100 DCU
    });

    it("Should distribute rewards correctly", async function () {
      const { rewardLogic, dcuToken, nftCollection, user, owner } =
        await loadFixture(deployContractsFixture);

      // Mint an NFT to the user
      await nftCollection.write.mint([getAddress(user.account.address)], {
        account: owner.account,
      });

      // Distribute rewards
      await rewardLogic.write.distributeReward([
        getAddress(user.account.address),
      ]);

      // Check user's token balance
      const balance = await dcuToken.read.balanceOf([
        getAddress(user.account.address),
      ]);
      expect(balance).to.equal(100n * 10n ** 18n); // 1 NFT * 100 DCU
    });

    it("Should update rewards when NFT balance changes", async function () {
      const { rewardLogic, nftCollection, user, owner } = await loadFixture(
        deployContractsFixture
      );

      // Check initial reward with no NFTs
      const initialReward = await rewardLogic.read.calculateReward([
        getAddress(user.account.address),
      ]);
      expect(initialReward).to.equal(0n);

      // Mint an NFT and check updated reward
      await nftCollection.write.mint([getAddress(user.account.address)], {
        account: owner.account,
      });
      const updatedReward = await rewardLogic.read.calculateReward([
        getAddress(user.account.address),
      ]);
      expect(updatedReward).to.equal(100n * 10n ** 18n); // 1 NFT * 100 DCU
    });
  });
});
