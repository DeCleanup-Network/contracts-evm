import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Input Validation", function () {
  let dipNft: any;
  let rewardManager: any;
  let dcuToken: any;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // First deploy DipNft (no constructor args needed)
    const DipNft = await ethers.getContractFactory("DipNft");
    dipNft = await DipNft.deploy();
    await dipNft.deployed();

    // Deploy DCU Token with temporary reward logic (will update later)
    // DCUToken only requires a reward logic address now (no max supply)
    const DCUToken = await ethers.getContractFactory("DCUToken");
    dcuToken = await DCUToken.deploy(await owner.getAddress());
    await dcuToken.deployed();

    // Deploy Reward Manager with DCU token
    const RewardManager = await ethers.getContractFactory("DCURewardManager");
    rewardManager = await RewardManager.deploy(dcuToken.address);
    await rewardManager.deployed();

    // Now update reward logic to point to the actual reward manager
    await dcuToken
      .connect(owner)
      .updateRewardLogicContract(rewardManager.address);

    // Setup rewardManager in DipNft
    await dipNft.connect(owner).setRewardsContract(rewardManager.address);

    // Verify user1 as POI in both contracts
    await dipNft.connect(owner).verifyPOI(await user1.getAddress());
    await rewardManager
      .connect(owner)
      .setPoiVerificationStatus(await user1.getAddress(), true);
  });

  describe("DipNft Input Validation", function () {
    it("Should reject updateImpactLevel with invalid impact level", async function () {
      // Mint an NFT first
      await dipNft.connect(user1).safeMint();
      const tokenId = 0; // First token ID

      // Try with impact level 0 (invalid)
      await expect(
        dipNft.connect(owner).updateImpactLevel(tokenId, 0)
      ).to.be.rejectedWith("Invalid impact level range");

      // Try with impact level 11 (invalid)
      const MAX_LEVEL = 10;
      await expect(
        dipNft.connect(owner).updateImpactLevel(tokenId, MAX_LEVEL + 1)
      ).to.be.rejectedWith("Invalid impact level range");

      // Should work with valid impact level
      await expect(dipNft.connect(owner).updateImpactLevel(tokenId, 5)).not.to
        .be.rejected;
    });

    it("Should reject distributeReward with invalid level", async function () {
      const userAddress = await user1.getAddress();

      // Try with level 0 (invalid)
      await expect(
        dipNft.connect(owner).distributeReward(userAddress, 0)
      ).to.be.rejectedWith("Invalid level range");

      // Try with level 11 (invalid)
      const MAX_LEVEL = 10;
      await expect(
        dipNft.connect(owner).distributeReward(userAddress, MAX_LEVEL + 1)
      ).to.be.rejectedWith("Invalid level range");

      // Should work with valid level
      await expect(dipNft.connect(owner).distributeReward(userAddress, 5)).not
        .to.be.rejected;
    });
  });

  describe("DCURewardManager Input Validation", function () {
    it("Should reject rewardImpactProductClaim with invalid level", async function () {
      const userAddress = await user1.getAddress();

      // Try with level 0 (invalid)
      await expect(
        rewardManager.connect(owner).rewardImpactProductClaim(userAddress, 0)
      ).to.be.rejectedWith("Invalid level range");

      // Try with level 11 (invalid)
      const MAX_LEVEL = 10;
      await expect(
        rewardManager
          .connect(owner)
          .rewardImpactProductClaim(userAddress, MAX_LEVEL + 1)
      ).to.be.rejectedWith("Invalid level range");

      // Should work with valid level
      await expect(
        rewardManager.connect(owner).rewardImpactProductClaim(userAddress, 5)
      ).not.to.be.rejected;
    });

    it("Should reject updateRewardAmounts with excessive reward amounts", async function () {
      const MAX_REWARD_AMOUNT = ethers.utils.parseEther("1000"); // 1000 ether
      const validAmount = ethers.utils.parseEther("100");
      const excessiveAmount = ethers.utils.parseEther("1001");

      // Try with excessive product claim reward
      await expect(
        rewardManager
          .connect(owner)
          .updateRewardAmounts(excessiveAmount, validAmount, validAmount)
      ).to.be.rejectedWith("Impact product claim reward too high");

      // Try with excessive referral reward
      await expect(
        rewardManager
          .connect(owner)
          .updateRewardAmounts(validAmount, excessiveAmount, validAmount)
      ).to.be.rejectedWith("Referral reward too high");

      // Try with excessive streak reward
      await expect(
        rewardManager
          .connect(owner)
          .updateRewardAmounts(validAmount, validAmount, excessiveAmount)
      ).to.be.rejectedWith("Streak reward too high");

      // Should work with valid amounts
      await expect(
        rewardManager
          .connect(owner)
          .updateRewardAmounts(validAmount, validAmount, validAmount)
      ).not.to.be.rejected;
    });

    it("Should reject claimRewards with zero amount", async function () {
      // Try to claim 0 tokens
      await expect(
        rewardManager.connect(user1).claimRewards(0)
      ).to.be.rejectedWith("Amount must be greater than zero");
    });

    it("Should reject setPoiVerificationStatus with zero address", async function () {
      // Try with zero address
      await expect(
        rewardManager
          .connect(owner)
          .setPoiVerificationStatus(ethers.constants.AddressZero, true)
      ).to.be.rejectedWith("Invalid user address");
    });
  });
});
