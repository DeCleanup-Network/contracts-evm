import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseEther } from "viem";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Define the Ignition Module for MyToken
const MyTokenModule = buildModule("MyTokenModule", (m) => {
  const initialSupply = m.getParameter("initialSupply", parseEther("1000000")); // 1,000,000 tokens
  const myToken = m.contract("MyToken", [initialSupply]);

  return { myToken };
});

describe("MyToken", function () {
  // Fixture to deploy the MyToken contract using Ignition
  async function deployMyTokenFixture() {
    const [owner, addr1, addr2] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy the MyToken module using Ignition
    const { myToken } = await hre.ignition.deploy(MyTokenModule);

    return {
      myToken,
      owner,
      addr1,
      addr2,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      const { myToken } = await loadFixture(deployMyTokenFixture);

      expect(await myToken.read.name()).to.equal("MyToken");
      expect(await myToken.read.symbol()).to.equal("MTK");
    });

    it("Should mint the initial supply to the deployer", async function () {
      const { myToken, owner } = await loadFixture(deployMyTokenFixture);

      const ownerBalance = await myToken.read.balanceOf([getAddress(owner.account.address)]);
      expect(ownerBalance).to.equal(parseEther("1000000")); // 1,000,000 tokens
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const { myToken, owner, addr1 } = await loadFixture(deployMyTokenFixture);

      const transferAmount = parseEther("100"); // 100 tokens
      await myToken.write.transfer([getAddress(addr1.account.address), transferAmount]);

      const addr1Balance = await myToken.read.balanceOf([getAddress(addr1.account.address)]);
      expect(addr1Balance).to.equal(transferAmount);

      const ownerBalance = await myToken.read.balanceOf([getAddress(owner.account.address)]);
      const expectedOwnerBalance = parseEther("999900"); // 1,000,000 - 100
      expect(ownerBalance).to.equal(expectedOwnerBalance);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const { myToken, addr1 } = await loadFixture(deployMyTokenFixture);

      const transferAmount = parseEther("1000001"); // More than the initial supply
      await expect(
        myToken.write.transfer([getAddress(addr1.account.address), transferAmount])
      ).to.be.rejectedWith("ERC20: transfer amount exceeds balance");
    });
  });

  describe("Events", function () {
    it("Should emit a Transfer event on transfers", async function () {
      const { myToken, owner, addr1, publicClient } = await loadFixture(deployMyTokenFixture);

      const transferAmount = parseEther("100"); // 100 tokens
      const hash = await myToken.write.transfer([getAddress(addr1.account.address), transferAmount]);
      await publicClient.waitForTransactionReceipt({ hash });

      // Get the Transfer events in the latest block
      const transferEvents = await myToken.getEvents.Transfer();
      expect(transferEvents).to.have.lengthOf(1);
      expect(transferEvents[0].args.from).to.equal(getAddress(owner.account.address));
      expect(transferEvents[0].args.to).to.equal(getAddress(addr1.account.address));
      expect(transferEvents[0].args.value).to.equal(transferAmount);
    });
  });
});