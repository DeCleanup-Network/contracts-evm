import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseEther } from "viem";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Define the Ignition Module for dcuToken
const DCU = buildModule("DCU", (m) => {
  const initialSupply = m.getParameter("initialSupply", parseEther("1000000")); // 1,000,000 tokens
  const dcuToken = m.contract("DCU", [initialSupply]);

  return { dcuToken };
});

describe("DCU", function () {
  // Fixture to deploy the dcuToken contract using Ignition
  async function deployDeCleanpFixture() {
    const [owner, addr1, addr2] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy the dcuToken module using Ignition
    const { dcuToken } = await hre.ignition.deploy(DCU);

    return {
      dcuToken,
      owner,
      addr1,
      addr2,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      const { dcuToken } = await loadFixture(deployDeCleanpFixture);

      expect(await dcuToken.read.name()).to.equal("DeCleanup");
      expect(await dcuToken.read.symbol()).to.equal("DCU");
    });

    it("Should mint the initial supply to the deployer", async function () {
      const { dcuToken, owner } = await loadFixture(deployDeCleanpFixture);

      const ownerBalance = await dcuToken.read.balanceOf([getAddress(owner.account.address)]);
      expect(ownerBalance).to.equal(parseEther("1000000")); // 1,000,000 tokens
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const { dcuToken, owner, addr1 } = await loadFixture(deployDeCleanpFixture);

      const transferAmount = parseEther("100"); // 100 tokens
      await dcuToken.write.transfer([getAddress(addr1.account.address), transferAmount]);

      const addr1Balance = await dcuToken.read.balanceOf([getAddress(addr1.account.address)]);
      expect(addr1Balance).to.equal(transferAmount);

      const ownerBalance = await dcuToken.read.balanceOf([getAddress(owner.account.address)]);
      const expectedOwnerBalance = parseEther("999900"); // 1,000,000 - 100
      expect(ownerBalance).to.equal(expectedOwnerBalance);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const { dcuToken, addr1 } = await loadFixture(deployDeCleanpFixture);

      const transferAmount = parseEther("1000001"); // More than the initial supply
      await expect(
        dcuToken.write.transfer([getAddress(addr1.account.address), transferAmount])
      ).to.be.rejectedWith("ERC20: transfer amount exceeds balance");
    });
  });

  describe("Events", function () {
    it("Should emit a Transfer event on transfers", async function () {
      const { dcuToken, owner, addr1, publicClient } = await loadFixture(deployDeCleanpFixture);

      const transferAmount = parseEther("100"); // 100 tokens
      const hash = await dcuToken.write.transfer([getAddress(addr1.account.address), transferAmount]);
      await publicClient.waitForTransactionReceipt({ hash });

      // Get the Transfer events in the latest block
      const transferEvents = await dcuToken.getEvents.Transfer();
      expect(transferEvents).to.have.lengthOf(1);
      expect(transferEvents[0].args.from).to.equal(getAddress(owner.account.address));
      expect(transferEvents[0].args.to).to.equal(getAddress(addr1.account.address));
      expect(transferEvents[0].args.value).to.equal(transferAmount);
    });
  });
});