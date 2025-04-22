# Deployment Guide for Arbitrum

This guide explains how to test, compile, deploy, and verify DCU contracts on Arbitrum networks.

## Prerequisites

1. Node.js and npm installed
2. An Ethereum wallet with Arbitrum ETH or Arbitrum Sepolia ETH for deployment
3. Infura or Alchemy API key for Arbitrum RPC access
4. Arbiscan API key for contract verification

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env` file:
   ```bash
   cp .env.example .env
   ```

3. Fill in your environment variables:
   - `ARBITRUM_ONE_RPC_URL`: Your Arbitrum Mainnet RPC URL
   - `ARBITRUM_SEPOLIA_RPC_URL`: Your Arbitrum Sepolia RPC URL
   - `PRIVATE_KEY`: Your wallet's private key (without 0x prefix)
   - `ARBISCAN_API_KEY`: Your Arbiscan API key

## Testing

Run tests:
```bash
npm test
```

## Compilation

Compile contracts:
```bash
npm run compile
```

## Deployment to Arbitrum

Deploy all contracts to Arbitrum Mainnet:
```bash
npm run deploy:arbitrum
```

Or to Arbitrum Sepolia testnet:
```bash
npm run deploy:arbitrum-testnet
```

This deploys the following contracts in order:
1. DCUToken
2. RewardLogic
3. DCUAccounting
4. DCUStorage
5. DCURewardManager
6. DipNft

## Contract Verification

Verify all contracts at once on Arbitrum Mainnet:
```bash
npm run verify:all-arbitrum
```

Or on Arbitrum Sepolia testnet:
```bash
npm run verify:all-arbitrum-testnet
```

You can also verify individual contracts:
```bash
npm run verify:arbitrum <CONTRACT_ADDRESS>
```

## Troubleshooting

- For RPC errors: Check your Infura/Alchemy API key
- For verification errors: Ensure your Arbiscan API key is correct
- Ensure you have enough ETH for gas fees
- For deployment failures: Check constructor arguments 