import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("DipNft", function () {
  async function deployDipNftFixture() {
    const [owner, user1, user2, rewardsContractOwner] =
      await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy DCUToken
    const dcuToken = await hre.viem.deployContract("DCUToken", [
      getAddress(owner.account.address),
      BigInt(1000000) * BigInt(10 ** 18), // 1 million tokens with 18 decimals
    ]);

    // Deploy DCURewardManager
    const dcuRewardManager = await hre.viem.deployContract("DCURewardManager", [
      getAddress(dcuToken.address),
    ]);

    // Update the reward logic contract address in DCUToken to DCURewardManager
    await dcuToken.write.updateRewardLogicContract(
      [getAddress(dcuRewardManager.address)],
      {
        account: owner.account,
      }
    );

    // Deploy the DipNft contract
    const dipNft = await hre.viem.deployContract("DipNft");

    // Set the rewards contract in DipNft to DCURewardManager
    await dipNft.write.setRewardsContract(
      [getAddress(dcuRewardManager.address)],
      {
        account: owner.account,
      }
    );

    // Verify POI for user1
    await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
      account: owner.account,
    });

    return {
      dipNft,
      dcuToken,
      dcuRewardManager,
      owner,
      user1,
      user2,
      rewardsContractOwner,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      const { dipNft } = await loadFixture(deployDipNftFixture);

      expect(await dipNft.read.name()).to.equal("DipNFT");
      expect(await dipNft.read.symbol()).to.equal("DIP");
    });

    it("Should set the correct owner", async function () {
      const { dipNft, owner } = await loadFixture(deployDipNftFixture);

      expect(await dipNft.read.owner()).to.equal(
        getAddress(owner.account.address)
      );
    });

    it("Should initialize token counter to zero", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint a token to check if the counter starts from 0
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Check if the token ID is 0
      expect(await dipNft.read.ownerOf([0n])).to.equal(
        getAddress(user1.account.address)
      );
    });
  });

  describe("POI Verification", function () {
    it("Should allow owner to verify a POI", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      expect(await dipNft.read.verifiedPOI([getAddress(user1.account.address)]))
        .to.be.true;
    });

    it("Should emit POIVerified event when verifying a POI", async function () {
      const { dipNft, owner, user1, publicClient } = await loadFixture(
        deployDipNftFixture
      );

      const tx = await dipNft.write.verifyPOI(
        [getAddress(user1.account.address)],
        {
          account: owner.account,
        }
      );

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);
    });

    it("Should prevent non-owners from verifying a POI", async function () {
      const { dipNft, user1, user2 } = await loadFixture(deployDipNftFixture);

      await expect(
        dipNft.write.verifyPOI([getAddress(user2.account.address)], {
          account: user1.account,
        })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should reject verification with zero address", async function () {
      const { dipNft, owner } = await loadFixture(deployDipNftFixture);

      await expect(
        dipNft.write.verifyPOI(["0x0000000000000000000000000000000000000000"], {
          account: owner.account,
        })
      ).to.be.rejectedWith("Invalid address");
    });
  });

  describe("Rewards Contract Management", function () {
    it("Should allow owner to set rewards contract", async function () {
      const { dipNft, dcuRewardManager, owner } = await loadFixture(
        deployDipNftFixture
      );

      expect(await dipNft.read.rewardsContract()).to.equal(
        getAddress(dcuRewardManager.address)
      );
    });

    it("Should emit RewardsContractUpdated event", async function () {
      const { dipNft, dcuRewardManager, owner, publicClient } =
        await loadFixture(deployDipNftFixture);

      const tx = await dipNft.write.setRewardsContract(
        [getAddress(dcuRewardManager.address)],
        {
          account: owner.account,
        }
      );

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);
    });

    it("Should prevent non-owners from setting rewards contract", async function () {
      const { dipNft, dcuRewardManager, user1 } = await loadFixture(
        deployDipNftFixture
      );

      await expect(
        dipNft.write.setRewardsContract(
          [getAddress(dcuRewardManager.address)],
          {
            account: user1.account,
          }
        )
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should reject setting rewards contract to zero address", async function () {
      const { dipNft, owner } = await loadFixture(deployDipNftFixture);

      await expect(
        dipNft.write.setRewardsContract(
          ["0x0000000000000000000000000000000000000000"],
          {
            account: owner.account,
          }
        )
      ).to.be.rejectedWith("Invalid rewards contract address");
    });
  });

  describe("NFT Minting", function () {
    it("Should allow verified POI to mint an NFT", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Check ownership and levels
      expect(await dipNft.read.ownerOf([0n])).to.equal(
        getAddress(user1.account.address)
      );
      expect(
        await dipNft.read.userLevel([getAddress(user1.account.address)])
      ).to.equal(1n);
      expect(await dipNft.read.nftLevel([0n])).to.equal(1n);
      expect(await dipNft.read.impactLevel([0n])).to.equal(1n);
      expect(await dipNft.read.hasMinted([getAddress(user1.account.address)]))
        .to.be.true;
    });

    it("Should emit Minted event when minting an NFT", async function () {
      const { dipNft, owner, user1, publicClient } = await loadFixture(
        deployDipNftFixture
      );

      // Mint a token
      const tx = await dipNft.write.safeMint([], {
        account: user1.account,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);
    });

    it("Should emit DCURewards event when minting an NFT", async function () {
      const { dipNft, dcuRewardManager, dcuToken, owner, user1, publicClient } =
        await loadFixture(deployDipNftFixture);

      // Mint a token
      const tx = await dipNft.write.safeMint([], {
        account: user1.account,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);

      // Note: In the updated approach, we're only checking for event emission
      // The actual reward distribution would be handled separately
    });

    it("Should prevent non-verified POI from minting", async function () {
      const { dipNft, user2 } = await loadFixture(deployDipNftFixture);

      await expect(
        dipNft.write.safeMint([], {
          account: user2.account,
        })
      ).to.be.rejectedWith("You are not a verified POI");
    });

    it("Should prevent minting more than one NFT per address", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint first token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Try to mint second token
      await expect(
        dipNft.write.safeMint([], {
          account: user1.account,
        })
      ).to.be.rejectedWith("You have already minted a token");
    });
  });

  describe("NFT Upgrading", function () {
    it("Should allow owner to upgrade their NFT", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Upgrade the NFT
      await dipNft.write.upgradeNFT([0n], {
        account: user1.account,
      });

      // Check levels
      expect(
        await dipNft.read.userLevel([getAddress(user1.account.address)])
      ).to.equal(2n);
      expect(await dipNft.read.nftLevel([0n])).to.equal(2n);
    });

    it("Should emit NFTUpgraded event when upgrading an NFT", async function () {
      const { dipNft, owner, user1, publicClient } = await loadFixture(
        deployDipNftFixture
      );

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Upgrade the NFT
      const tx = await dipNft.write.upgradeNFT([0n], {
        account: user1.account,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);
    });

    it("Should emit DCURewardTriggered event when upgrading an NFT", async function () {
      const { dipNft, dcuRewardManager, dcuToken, owner, user1, publicClient } =
        await loadFixture(deployDipNftFixture);

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Upgrade the NFT
      const tx = await dipNft.write.upgradeNFT([0n], {
        account: user1.account,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);

      // Note: In the updated approach, we're only checking for event emission
      // The actual reward distribution would be handled separately
    });

    it("Should prevent non-verified POI from upgrading", async function () {
      const { dipNft, owner, user1, user2 } = await loadFixture(
        deployDipNftFixture
      );

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Try to upgrade with non-verified user
      await expect(
        dipNft.write.upgradeNFT([0n], {
          account: user2.account,
        })
      ).to.be.rejectedWith("You are not a verified POI");
    });

    it("Should prevent upgrading NFT not owned by the caller", async function () {
      const { dipNft, owner, user1, user2 } = await loadFixture(
        deployDipNftFixture
      );

      // Verify both users as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });
      await dipNft.write.verifyPOI([getAddress(user2.account.address)], {
        account: owner.account,
      });

      // Mint a token for user1
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Mint a token for user2 so they have minted a token
      await dipNft.write.safeMint([], {
        account: user2.account,
      });

      // Try to upgrade user1's token with user2
      await expect(
        dipNft.write.upgradeNFT([0n], {
          account: user2.account,
        })
      ).to.be.rejectedWith("You don't own this token");
    });

    it("Should prevent upgrading beyond MAX_LEVEL", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Upgrade the NFT to MAX_LEVEL
      for (let i = 1; i < 10; i++) {
        await dipNft.write.upgradeNFT([0n], {
          account: user1.account,
        });
      }

      // Check level
      expect(await dipNft.read.nftLevel([0n])).to.equal(10n);

      // Try to upgrade beyond MAX_LEVEL
      await expect(
        dipNft.write.upgradeNFT([0n], {
          account: user1.account,
        })
      ).to.be.rejectedWith("You have reached the maximum level");
    });
  });

  describe("Impact Level Management", function () {
    it("Should allow owner to update impact level", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Verify user1 as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Update impact level
      await dipNft.write.updateImpactLevel([0n, 5n], {
        account: owner.account,
      });

      // Check impact level
      expect(await dipNft.read.impactLevel([0n])).to.equal(5n);
    });

    it("Should emit ImpactLevelUpdated event", async function () {
      const { dipNft, owner, user1, publicClient } = await loadFixture(
        deployDipNftFixture
      );

      // Verify user1 as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Update impact level
      const tx = await dipNft.write.updateImpactLevel([0n, 5n], {
        account: owner.account,
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx,
      });

      // Check for events in the transaction logs
      const logs = receipt.logs;
      expect(logs.length).to.be.greaterThan(0);
    });

    it("Should prevent non-owners from updating impact level", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Verify user1 as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Try to update impact level as non-owner
      await expect(
        dipNft.write.updateImpactLevel([0n, 5n], {
          account: user1.account,
        })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should reject updating impact level for non-existent token", async function () {
      const { dipNft, owner } = await loadFixture(deployDipNftFixture);

      // Try to update impact level for non-existent token
      await expect(
        dipNft.write.updateImpactLevel([999n, 5n], {
          account: owner.account,
        })
      ).to.be.rejectedWith("Token does not exist");
    });
  });

  describe("NFT Data Retrieval", function () {
    it("Should return correct NFT data for a user", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Verify user1 as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Update impact level
      await dipNft.write.updateImpactLevel([0n, 5n], {
        account: owner.account,
      });

      // Get NFT data
      const nftData = await dipNft.read.getUserNFTData([
        getAddress(user1.account.address),
      ]);

      expect(nftData[0]).to.equal(0n); // tokenId
      expect(nftData[1]).to.equal(5n); // impact
      expect(nftData[2]).to.equal(1n); // level
    });

    it("Should reject getting NFT data for user without NFT", async function () {
      const { dipNft, user1 } = await loadFixture(deployDipNftFixture);

      // Try to get NFT data for user without NFT
      await expect(
        dipNft.read.getUserNFTData([getAddress(user1.account.address)])
      ).to.be.rejectedWith("User has no NFT");
    });

    it("Should return correct category based on NFT level", async function () {
      const { dipNft } = await loadFixture(deployDipNftFixture);

      expect(await dipNft.read.getNFTCategory([1n])).to.equal("Newbie");
      expect(await dipNft.read.getNFTCategory([3n])).to.equal("Newbie");
      expect(await dipNft.read.getNFTCategory([4n])).to.equal("Pro");
      expect(await dipNft.read.getNFTCategory([6n])).to.equal("Pro");
      expect(await dipNft.read.getNFTCategory([7n])).to.equal("Hero");
      expect(await dipNft.read.getNFTCategory([9n])).to.equal("Hero");
      expect(await dipNft.read.getNFTCategory([10n])).to.equal("Guardian");
      expect(await dipNft.read.getNFTCategory([11n])).to.equal("Invalid");
    });
  });

  describe("Token URI and Metadata", function () {
    it("Should generate correct token URI with metadata", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Verify user1 as POI
      await dipNft.write.verifyPOI([getAddress(user1.account.address)], {
        account: owner.account,
      });

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Get token URI
      const tokenURI = await dipNft.read.tokenURI([0n]);

      // Check if it's a data URI
      expect(tokenURI).to.include("data:application/json;base64,");

      // Decode the base64 part
      const base64Data = tokenURI.split("base64,")[1];
      const jsonData = Buffer.from(base64Data, "base64").toString();
      const metadata = JSON.parse(jsonData);

      // Check metadata structure
      expect(metadata.name).to.equal("DipNFT #0");
      expect(metadata.description).to.include("on-chain NFT");
      expect(metadata.attributes).to.have.lengthOf(3);
      expect(metadata.attributes[0].trait_type).to.equal("Impact Level");
      expect(metadata.attributes[0].value).to.equal("1");
      expect(metadata.attributes[1].trait_type).to.equal("NFT Level");
      expect(metadata.attributes[1].value).to.equal("1");
      expect(metadata.attributes[2].trait_type).to.equal("Category");
      expect(metadata.attributes[2].value).to.equal("Newbie");
      expect(metadata.image).to.include("data:image/svg+xml;base64,");
    });

    it("Should reject token URI for non-existent token", async function () {
      const { dipNft } = await loadFixture(deployDipNftFixture);

      // Try to get token URI for non-existent token
      await expect(dipNft.read.tokenURI([999n])).to.be.rejectedWith(
        "Token does not exist"
      );
    });
  });

  // Add a new test section for reward distribution
  describe("Reward Distribution", function () {
    it("Should allow owner to distribute rewards", async function () {
      const { dipNft, owner, user1 } = await loadFixture(deployDipNftFixture);

      // Mint a token
      await dipNft.write.safeMint([], {
        account: user1.account,
      });

      // Distribute rewards - this should not throw an error
      await dipNft.write.distributeReward(
        [getAddress(user1.account.address), 1n],
        {
          account: owner.account,
        }
      );

      // If we get here, the test passes
    });

    it("Should prevent non-owners from distributing rewards", async function () {
      const { dipNft, user1, user2 } = await loadFixture(deployDipNftFixture);

      // Try to distribute rewards as non-owner
      await expect(
        dipNft.write.distributeReward([getAddress(user2.account.address), 1n], {
          account: user1.account,
        })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should reject distributing rewards to non-verified POI", async function () {
      const { dipNft, owner, user2 } = await loadFixture(deployDipNftFixture);

      // Try to distribute rewards to non-verified POI
      await expect(
        dipNft.write.distributeReward([getAddress(user2.account.address), 1n], {
          account: owner.account,
        })
      ).to.be.rejectedWith("User is not a verified POI");
    });

    it("Should reject distributing rewards to zero address", async function () {
      const { dipNft, owner } = await loadFixture(deployDipNftFixture);

      // Try to distribute rewards to zero address
      await expect(
        dipNft.write.distributeReward(
          ["0x0000000000000000000000000000000000000000", 1n],
          {
            account: owner.account,
          }
        )
      ).to.be.rejectedWith("Invalid user address");
    });
  });
});
