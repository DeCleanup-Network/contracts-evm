# DeCleanup Network Smart Contracts

This package provides the smart contracts for the DeCleanup Network, including TypeChain-generated type definitions for type-safe contract interactions.

## Installation

```bash
npm install @decleanup/contracts
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

async function claimRewards(signer: ethers.Signer, submissionId: bigint) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const rewardManager = contracts.DCURewardManager.connect(signer);
  const rewardLogic = contracts.RewardLogic.connect(signer);
  
  // Check if rewards are available
  const isAvailable = await rewardLogic.isRewardAvailable(submissionId);
  if (!isAvailable) {
    throw new Error('Rewards not available for this submission');
  }
  
  // Claim rewards
  const tx = await rewardManager.claimRewards(submissionId);
  await tx.wait();
}
```

### Example: NFT Operations

```typescript
import { DCUContracts, Networks } from '@decleanup/contracts';

async function mintNFT(signer: ethers.Signer, to: string, tokenURI: string) {
  const contracts = new DCUContracts(Networks.ARBITRUM_SEPOLIA);
  const nft = contracts.DipNft.connect(signer);
  
  // Mint new NFT
  const tx = await nft.mint(to, tokenURI);
  await tx.wait();
  
  // Get token ID
  const receipt = await tx.wait();
  const event = receipt.logs.find(log => log.fragment.name === 'Transfer');
  const tokenId = event?.args[2];
  
  return tokenId;
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

## Contributing

To contribute to this package:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT 