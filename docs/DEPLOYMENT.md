# Deployment Guide

This guide explains how to test, compile, deploy, and verify DCU contracts.

## Prerequisites

1. Node.js and npm installed
2. An Ethereum wallet with Sepolia ETH for deployment
3. Infura or Alchemy API key for Sepolia RPC access
4. Etherscan API key for contract verification

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
   - `SEPOLIA_RPC_URL`: Your Sepolia RPC URL
   - `PRIVATE_KEY`: Your wallet's private key (without 0x prefix)
   - `ETHERSCAN_API_KEY`: Your Etherscan API key

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

## Deployment to Sepolia

Deploy all contracts:
```bash
npm run deploy:testnet
```

This deploys the following contracts in order:
1. DCUStorage
2. NFTCollection
3. DCUAccounting
4. DCURewardManager
5. RewardLogic

### Latest Deployment

Contracts deployed to Sepolia:

| Contract | Address |
|----------|---------|
| DCUStorage | 0x6B0b410c922713d359f0fe34F710c4D77351DEC5 |
| NFTCollection | 0xf3B81c0Bb5089FA4244f6eE633E1205453C65b37 |
| DCUAccounting | 0xF2c3add9b1a4075086e3CE693DCD9Efee81918Ff |
| DCURewardManager | 0x589679A4aB985E7e50f469507397b2d7a5279c41 |
| RewardLogic | 0xE23e8f18b7CF16201F7D4F50fBf28A654433CE7A |

View on [Sepolia Etherscan](https://sepolia.etherscan.io/).

## Contract Verification

Verify all contracts at once:
```bash
npm run verify:all
```

Or verify individual contracts:
```bash
npm run verify:testnet <CONTRACT_ADDRESS>
```

## Troubleshooting

- For RPC errors: Check your Infura/Alchemy API key
- For verification errors: Ensure your Etherscan API key is correct
- Ensure you have enough Sepolia ETH for gas fees
- For deployment failures: Check constructor arguments 