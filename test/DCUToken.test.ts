import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("DCUToken", function () {
  async function deployTokenFixture() {
    const [owner, user] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    const dcuToken = await hre.viem.deployContract("DCUToken");

    return {
      dcuToken,
      owner,
      user,
      publicClient,
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

    it("Should prevent non-owners from minting", async function () {
      const { dcuToken, user } = await loadFixture(deployTokenFixture);

      const amount = 100n * 10n ** 18n; // 100 tokens
      await expect(
        dcuToken.write.mint([getAddress(user.account.address), amount], {
          account: user.account,
        })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });
  });
});
