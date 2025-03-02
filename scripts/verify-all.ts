import { run } from "hardhat";
import * as fs from "fs";
import * as path from "path";

// Read deployed addresses from Ignition deployment file
const deployedAddressesPath = path.join(__dirname, "deployed_addresses.json");
const deployedAddresses = JSON.parse(
  fs.readFileSync(deployedAddressesPath, "utf8")
);

// Map the contract names to their addresses
const CONTRACT_ADDRESSES = {
  DCUStorage: deployedAddresses["DCUContracts#DCUStorage"],
  NFTCollection: deployedAddresses["DCUContracts#NFTCollection"],
  DCUAccounting: deployedAddresses["DCUContracts#DCUAccounting"],
  DCURewardManager: deployedAddresses["DCUContracts#DCURewardManager"],
  RewardLogic: deployedAddresses["DCUContracts#RewardLogic"],
};

async function main() {
  console.log("Starting contract verification...");
  console.log("\nBefore running verification, please ensure:");
  console.log("1. You have set ETHERSCAN_API_KEY in your .env file");
  console.log("2. The hardhat.config.ts file has etherscan configuration\n");
  console.log(
    "Using addresses from Ignition deployment file:",
    deployedAddressesPath
  );
  console.log(CONTRACT_ADDRESSES);

  // Verify DCUStorage (no constructor args)
  console.log("\nVerifying DCUStorage...");
  try {
    await run("verify:verify", {
      address: CONTRACT_ADDRESSES.DCUStorage,
      constructorArguments: [],
    });
    console.log("✅ DCUStorage verified successfully!");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ DCUStorage already verified!");
    } else {
      console.error("❌ Failed to verify DCUStorage:", error);
    }
  }

  // Verify NFTCollection (no constructor args)
  console.log("\nVerifying NFTCollection...");
  try {
    await run("verify:verify", {
      address: CONTRACT_ADDRESSES.NFTCollection,
      constructorArguments: [],
    });
    console.log("✅ NFTCollection verified successfully!");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ NFTCollection already verified!");
    } else {
      console.error("❌ Failed to verify NFTCollection:", error);
    }
  }

  // Verify DCUAccounting (with constructor args)
  console.log("\nVerifying DCUAccounting...");
  try {
    await run("verify:verify", {
      address: CONTRACT_ADDRESSES.DCUAccounting,
      constructorArguments: [CONTRACT_ADDRESSES.DCUStorage],
    });
    console.log("✅ DCUAccounting verified successfully!");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ DCUAccounting already verified!");
    } else {
      console.error("❌ Failed to verify DCUAccounting:", error);
    }
  }

  // Verify DCURewardManager (with constructor args)
  console.log("\nVerifying DCURewardManager...");
  try {
    await run("verify:verify", {
      address: CONTRACT_ADDRESSES.DCURewardManager,
      constructorArguments: [CONTRACT_ADDRESSES.DCUStorage],
    });
    console.log("✅ DCURewardManager verified successfully!");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ DCURewardManager already verified!");
    } else {
      console.error("❌ Failed to verify DCURewardManager:", error);
    }
  }

  // Verify RewardLogic (with constructor args)
  console.log("\nVerifying RewardLogic...");
  try {
    await run("verify:verify", {
      address: CONTRACT_ADDRESSES.RewardLogic,
      constructorArguments: [
        CONTRACT_ADDRESSES.DCUStorage,
        CONTRACT_ADDRESSES.NFTCollection,
      ],
    });
    console.log("✅ RewardLogic verified successfully!");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ RewardLogic already verified!");
    } else {
      console.error("❌ Failed to verify RewardLogic:", error);
    }
  }

  console.log("\nVerification process completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
