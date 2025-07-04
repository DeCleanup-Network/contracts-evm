# DeCleanup Network Smart Contracts Package

This package provides the smart contracts for the DeCleanup Network, including TypeChain-generated type definitions for type-safe contract interactions.

## Installation

```bash
npm install @decleanup/contracts
```

## Overview

The DeCleanup Network smart contracts package includes all core contracts for the environmental cleanup platform:

### Core Token Contracts
- **DCUToken** - Main ERC-20 utility token with dynamic supply
- **DCUStorage** - Token storage with TGE restrictions and staking
- **DCUAccounting** - Token deposit/withdrawal management

### NFT & Reward Contracts
- **DipNft** - Soulbound NFTs representing Impact Products
- **NFTCollection** - Basic NFT collection for testing
- **DCURewardManager** - Manages DCU rewards for various activities
- **RewardLogic** - Handles reward distribution logic

### Additional Contracts
- **Submission** - Handles form submissions from the DeCleanup dapp

## Package Generation

### Prerequisites

1. **Compile Contracts:**
   ```bash
   npm run compile
   ```

2. **Generate TypeChain Types:**
   ```bash
   npm run typechain
   ```

3. **Deploy Contracts:**
   ```bash
   # For Arbitrum Mainnet
   npm run deploy:arbitrum
   
   # For Arbitrum Sepolia Testnet
   npm run deploy:arbitrum-testnet
   ```

### Generating the Package

#### For Arbitrum Mainnet
```bash
npm run generate-package:arbitrum
```

#### For Arbitrum Sepolia Testnet
```bash
npm run generate-package:arbitrum-sepolia
```

#### For Custom Network
```bash
npm run generate-package <network-name>
```

### Package Structure

The generated package will have the following structure:

```
package/
├── package.json
├── index.js
├── index.d.ts
└── <network-name>/
    ├── config.json
    ├── index.js
    ├── index.d.ts
    ├── artifacts/
    │   ├── DCUToken/
    │   │   ├── abi.json
    │   │   └── bytecode.json
    │   ├── DipNft/
    │   │   ├── abi.json
    │   │   └── bytecode.json
    │   └── ... (other contracts)
    └── typechain/
        ├── contracts/
        ├── factories/
        └── ... (TypeChain files)
```

## Usage

### Basic Setup

```typescript
import { ethers } from 'ethers';
import { DCUContracts, Networks } from '@decleanup/contracts';

// Initialize with a specific network
const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider('YOUR_RPC_URL');
const signer = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);

// Get contract instances with full type inference
const token = contracts.DCUToken.connect(signer);
const rewardLogic = contracts.RewardLogic.connect(signer);
const accounting = contracts.DCUAccounting.connect(signer);
const storage = contracts.DCUStorage.connect(signer);
const rewardManager = contracts.DCURewardManager.connect(signer);
const dipNft = contracts.DipNft.connect(signer);
const submission = contracts.Submission.connect(signer);
const nftCollection = contracts.NFTCollection.connect(signer);
```

### Contract Information

Each contract provides the following information:

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);

// Contract address
console.log(contracts.DCUToken.address);

// Contract ABI
console.log(contracts.DCUToken.abi);

// Network information
console.log(contracts.DCUToken.network); // 'arbitrum-sepolia' or 'arbitrum'
console.log(contracts.DCUToken.chainId); // Chain ID

// Type-safe contract instance
const token = contracts.DCUToken.connect(signer);
```

### Network Support

The package supports multiple networks through the `Networks` enum:

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

// Initialize for Arbitrum Sepolia
const sepoliaContracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);

// Initialize for Arbitrum Mainnet
const mainnetContracts = new DCUContracts(Networks.ARBITRUM);

// Check network information
console.log(sepoliaContracts.DCUToken.chainId); // 421614
console.log(mainnetContracts.DCUToken.chainId); // 42161
```

### Example: Token Operations

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function transferTokens(signer: ethers.Signer, recipient: string, amount: bigint) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const token = contracts.DCUToken.connect(signer);
  
  // Type-safe transfer
  const tx = await token.transfer(recipient, amount);
  await tx.wait();
  
  // Type-safe balance check
  const balance = await token.balanceOf(recipient);
  return balance;
}
```

### Example: Reward Operations

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function claimRewards(signer: ethers.Signer, amount: bigint) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const rewardManager = contracts.DCURewardManager.connect(signer);
  
  // Claim rewards
  const tx = await rewardManager.claimRewards(amount);
  await tx.wait();
  
  return tx;
}
```

### Example: NFT Operations

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function mintNFT(signer: ethers.Signer) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const nft = contracts.DipNft.connect(signer);
  
  // Mint new NFT (requires PoI verification)
  const tx = await nft.safeMint();
  await tx.wait();
  
  // Get token ID
  const receipt = await tx.wait();
  const event = receipt.logs.find(log => log.fragment.name === 'Transfer');
  const tokenId = event?.args[2];
  
  return tokenId;
}
```

### Example: Submission Operations

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function createSubmission(signer: ethers.Signer, dataURI: string) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const submission = contracts.Submission.connect(signer);
  
  // Create a new submission
  const tx = await submission.createSubmission(dataURI);
  await tx.wait();
  
  // Get submission ID from event
  const receipt = await tx.wait();
  const event = receipt.logs.find(log => log.fragment.name === 'SubmissionCreated');
  const submissionId = event?.args[0];
  
  return submissionId;
}
```

## Type Safety

The package includes TypeChain-generated type definitions, providing:

- Full type inference for all contract methods
- Type checking for function parameters and return values
- Autocompletion in IDEs
- Compile-time error checking

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
const token = contracts.DCUToken.connect(signer);

// Type-safe method calls
await token.transfer(recipient, amount); // ✅ Correct
await token.transfer(recipient, "100");  // ❌ Error: amount must be bigint
```

## Error Handling

All contract interactions include proper error handling:

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function safeTransfer(signer: ethers.Signer, recipient: string, amount: bigint) {
  try {
    const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
    const token = contracts.DCUToken.connect(signer);
    const tx = await token.transfer(recipient, amount);
    await tx.wait();
    return true;
  } catch (error) {
    console.error('Transfer failed:', error);
    return false;
  }
}
```

## Adding New Contracts

To add a new contract to the package:

1. **Add to Contract List**: Update the `contracts` array in `scripts/generate-package.ts`
   ```typescript
   const contracts: ContractInfo[] = [
     // ... existing contracts
     { name: "NewContract", path: "NewContract.sol" },
   ];
   ```

2. **Update Deployment Script**: Add deployment logic to `scripts/deploy-arbitrum.ts`
   ```typescript
   // Deploy NewContract
   const NewContract = await ethers.getContractFactory("NewContract");
   const newContract = await NewContract.deploy(/* constructor args */);
   await newContract.deployed();
   const newContractAddress = newContract.address;
   ```

3. **Update Ignition Module**: Add to `ignition/modules/DCUContracts.ts`
   ```typescript
   const newContract = m.contract("NewContract", [/* constructor args */]);
   ```

4. **Update Deployed Addresses**: Add to the `deployedAddresses` object
   ```typescript
   const deployedAddresses = {
     // ... existing addresses
     NewContract: newContractAddress,
   };
   ```

## Troubleshooting

### Common Issues

1. **Missing Contract Artifacts**
   - Ensure contracts are compiled: `npm run compile`
   - Check that the contract path in `generate-package.ts` is correct

2. **Missing Deployment Addresses**
   - Deploy contracts first: `npm run deploy:arbitrum`
   - Verify `deployed_addresses.json` exists and contains all contracts

3. **TypeChain Types Missing**
   - Generate types: `npm run typechain`
   - Check that `typechain-types/` directory exists

4. **Network Not Supported**
   - Add network configuration to `generate-package.ts`
   - Update deployment scripts for the new network

### Verification

After generating the package:

1. **Check Package Structure**: Verify all contracts are included
2. **Test Integration**: Use the package in a test project
3. **Verify Addresses**: Confirm contract addresses match deployments
4. **Test TypeScript**: Ensure TypeScript types work correctly

## Publishing

To publish the package to npm:

1. **Build Package**: Generate the package for all networks
2. **Test Package**: Verify functionality in a test environment
3. **Update Version**: Increment version in `package.json`
4. **Publish**: Use `npm publish` in the package directory

## Contributing

To contribute to this package:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT 