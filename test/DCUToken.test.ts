import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("DCUToken", function () {
  async function deployTokenFixture() {
    const [owner, user] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy a mock reward logic contract first (we'll use owner address for simplicity)
    const rewardLogicAddress = owner.account.address;
    const maxSupply = 1000000n * 10n ** 18n; // 1 million tokens with 18 decimals

    const dcuToken = await hre.viem.deployContract("DCUToken", [
      rewardLogicAddress,
      maxSupply,
    ]);

    return {
      dcuToken,
      owner,
      user,
      publicClient,
      rewardLogicAddress,
      maxSupply,
    };
  }

  describe("Basic Token Operations", function () {
    it("Should set the correct name and symbol", async function () {
      const { dcuToken } = await loadFixture(deployTokenFixture);

      expect(await dcuToken.read.name()).to.equal("DCU Token");
      expect(await dcuToken.read.symbol()).to.equal("DCU");
    });

    it("Should allow owner to mint tokens", async function () {
      const { dcuToken, owner, user } = await loadFixture(deployTokenFixture);

      const amount = 100n * 10n ** 18n; // 100 tokens
      await dcuToken.write.mint([getAddress(user.account.address), amount], {
        account: owner.account,
      });

      const balance = await dcuToken.read.balanceOf([
        getAddress(user.account.address),
      ]);
      expect(balance).to.equal(amount);
    });

    it("Should allow owner to burn tokens", async function () {
      const { dcuToken, owner, user } = await loadFixture(deployTokenFixture);

      // First mint some tokens
      const amount = 100n * 10n ** 18n; // 100 tokens
      await dcuToken.write.mint([getAddress(user.account.address), amount], {
        account: owner.account,
      });

      // Then burn them
      await dcuToken.write.burn([getAddress(user.account.address), amount], {
        account: owner.account,
      });

      const balance = await dcuToken.read.balanceOf([
        getAddress(user.account.address),
      ]);
      expect(balance).to.equal(0n);
    });

    it("Should prevent non-reward-logic from minting", async function () {
      const { dcuToken, user } = await loadFixture(deployTokenFixture);

      const amount = 100n * 10n ** 18n; // 100 tokens
      await expect(
        dcuToken.write.mint([getAddress(user.account.address), amount], {
          account: user.account,
        })
      ).to.be.rejectedWith("Only RewardLogic Contract can mint");
    });

    it("Should allow owner to update reward logic contract", async function () {
      const { dcuToken, owner, user } = await loadFixture(deployTokenFixture);

      // Get the initial reward logic contract
      const initialRewardLogic = await dcuToken.read.rewardLogicContract();

      // Update to a new address (user's address for this test)
      await dcuToken.write.updateRewardLogicContract(
        [getAddress(user.account.address)],
        {
          account: owner.account,
        }
      );

      // Check that the reward logic contract was updated
      const newRewardLogic = await dcuToken.read.rewardLogicContract();
      expect(newRewardLogic).to.equal(getAddress(user.account.address));
      expect(newRewardLogic).to.not.equal(initialRewardLogic);

      // Now user should be able to mint tokens
      const amount = 100n * 10n ** 18n; // 100 tokens
      await dcuToken.write.mint([getAddress(owner.account.address), amount], {
        account: user.account,
      });

      // Check the balance
      const balance = await dcuToken.read.balanceOf([
        getAddress(owner.account.address),
      ]);
      expect(balance).to.equal(amount);
    });

    it("Should prevent non-owners from updating reward logic contract", async function () {
      const { dcuToken, user } = await loadFixture(deployTokenFixture);

      // Try to update reward logic contract as non-owner
      await expect(
        dcuToken.write.updateRewardLogicContract(
          [getAddress(user.account.address)],
          {
            account: user.account,
          }
        )
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });
  });
});
