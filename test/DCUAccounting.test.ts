import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("DCUAccounting", function () {
  async function deployAccountingFixture() {
    const [owner, user] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    const dcuToken = await hre.viem.deployContract("DCUToken");
    const dcuAccounting = await hre.viem.deployContract("DCUAccounting", [
      dcuToken.address,
    ]);

    // Mint some tokens to user
    await dcuToken.write.mint(
      [getAddress(user.account.address), 1000n * 10n ** 18n],
      {
        account: owner.account,
      }
    );

    return {
      dcuToken,
      dcuAccounting,
      owner,
      user,
      publicClient,
    };
  }

  describe("Deposit and Withdrawal", function () {
    it("Should allow deposits", async function () {
      const { dcuToken, dcuAccounting, user } = await loadFixture(
        deployAccountingFixture
      );

      const amount = 100n * 10n ** 18n; // 100 tokens
      await dcuToken.write.approve([dcuAccounting.address, amount], {
        account: user.account,
      });

      await dcuAccounting.write.deposit([amount], {
        account: user.account,
      });

      const balance = await dcuAccounting.read.balances([
        getAddress(user.account.address),
      ]);
      expect(balance).to.equal(amount);
    });

    it("Should allow withdrawals", async function () {
      const { dcuToken, dcuAccounting, user } = await loadFixture(
        deployAccountingFixture
      );

      const amount = 100n * 10n ** 18n; // 100 tokens
      await dcuToken.write.approve([dcuAccounting.address, amount], {
        account: user.account,
      });

      await dcuAccounting.write.deposit([amount], {
        account: user.account,
      });

      await dcuAccounting.write.withdraw([amount], {
        account: user.account,
      });

      const balance = await dcuAccounting.read.balances([
        getAddress(user.account.address),
      ]);
      expect(balance).to.equal(0n);
    });

    it("Should prevent withdrawals exceeding balance", async function () {
      const { dcuAccounting, user } = await loadFixture(
        deployAccountingFixture
      );

      await expect(
        dcuAccounting.write.withdraw([1n * 10n ** 18n], {
          account: user.account,
        })
      ).to.be.rejectedWith("Insufficient balance");
    });
  });
});
