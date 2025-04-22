import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-viem";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import * as dotenv from "dotenv";

dotenv.config();

const PRIVATE_KEY =
  process.env.PRIVATE_KEY ||
  "0x0000000000000000000000000000000000000000000000000000000000000000";
const ARBITRUM_ONE_RPC_URL = process.env.ARBITRUM_ONE_RPC_URL || "";
const ARBITRUM_SEPOLIA_RPC_URL = process.env.ARBITRUM_SEPOLIA_RPC_URL || "";
const ARBISCAN_API_KEY = process.env.ARBISCAN_API_KEY || "";

const config = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    arbitrum: {
      url: ARBITRUM_ONE_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 42161,
    },
    arbitrumSepolia: {
      url: ARBITRUM_SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 421614,
    },
  },
  etherscan: {
    apiKey: {
      arbitrum: ARBISCAN_API_KEY,
      arbitrumSepolia: ARBISCAN_API_KEY,
    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io/",
        },
      },
    ],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
    alwaysGenerateOverloads: false,
    externalArtifacts: ["externalArtifacts/*.json"],
    dontOverrideCompile: false,
  },
} as const;

export default config;
