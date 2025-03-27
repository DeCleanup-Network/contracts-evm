import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Ignition module for deploying all DCU contracts
 */
export default buildModule("DCUContracts", (m) => {
  // Deploy the DCUStorage contract first
  const dcuStorage = m.contract("DCUStorage");

  // Deploy the DCUAccounting contract with DCUStorage address
  const dcuAccounting = m.contract("DCUAccounting", [dcuStorage]);

  // Deploy the NFTCollection contract
  const nftCollection = m.contract("NFTCollection");

  // Deploy the RewardLogic contract with DCUStorage and NFTCollection addresses
  const rewardLogic = m.contract("RewardLogic", [dcuStorage, nftCollection]);

  // Deploy the DCU token with RewardLogic contract address (no max supply parameter anymore)
  const dcuToken = m.contract("DCUToken", [rewardLogic]);

  // Deploy the DCURewardManager contract with DCUToken address
  const dcuRewardManager = m.contract("DCURewardManager", [dcuToken]);

  // Return all deployed contracts
  return {
    dcuStorage,
    dcuAccounting,
    nftCollection,
    rewardLogic,
    dcuToken,
    dcuRewardManager,
  };
});
