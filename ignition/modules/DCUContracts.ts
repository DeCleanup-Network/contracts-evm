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

  // Deploy the DCURewardManager contract with DCUStorage address
  const dcuRewardManager = m.contract("DCURewardManager", [dcuStorage]);

  // Return all deployed contracts
  return {
    dcuStorage,
    dcuAccounting,
    nftCollection,
    rewardLogic,
    dcuRewardManager,
  };
});
