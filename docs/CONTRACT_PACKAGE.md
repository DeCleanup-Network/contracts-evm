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
import { DCUToken, RewardLogic, DCUAccounting, DCUStorage, DCURewardManager, DipNft } from '@decleanup/contracts';

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider('YOUR_RPC_URL');
const signer = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);

// Get contract instances with full type inference
const token = DCUToken.contract.connect(signer);
const rewardLogic = RewardLogic.contract.connect(signer);
const accounting = DCUAccounting.contract.connect(signer);
const storage = DCUStorage.contract.connect(signer);
const rewardManager = DCURewardManager.contract.connect(signer);
const dipNft = DipNft.contract.connect(signer);
```

### Contract Information

Each contract export contains the following information:

```typescript
import { DCUToken } from '@decleanup/contracts';

// Contract address
console.log(DCUToken.address);

// Contract ABI
console.log(DCUToken.abi);

// Network information
console.log(DCUToken.network); // 'arbitrum' or 'arbitrum-testnet'
console.log(DCUToken.chainId); // Chain ID

// Type-safe contract instance
const token = DCUToken.contract.connect(signer);
```

### Network Information

```typescript
import { network } from '@decleanup/contracts';

console.log(network.name);      // Network name
console.log(network.chainId);   // Chain ID
console.log(network.deployedAt); // Deployment timestamp
```

### Example: Token Operations

```typescript
import { DCUToken } from '@decleanup/contracts';

async function transferTokens(signer: ethers.Signer, recipient: string, amount: bigint) {
  const token = DCUToken.contract.connect(signer);
  
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
import { RewardLogic, DCURewardManager } from '@decleanup/contracts';

async function claimRewards(signer: ethers.Signer, submissionId: bigint) {
  const rewardManager = DCURewardManager.contract.connect(signer);
  const rewardLogic = RewardLogic.contract.connect(signer);
  
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
import { DipNft } from '@decleanup/contracts';

async function mintNFT(signer: ethers.Signer, to: string, tokenURI: string) {
  const nft = DipNft.contract.connect(signer);
  
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
import { DCUToken } from '@decleanup/contracts';

const token = DCUToken.contract.connect(signer);

// Type-safe method calls
await token.transfer(recipient, amount); // ✅ Correct
await token.transfer(recipient, "100");  // ❌ Error: amount must be bigint
```

## Network Support

The package supports both Arbitrum mainnet and testnet deployments. The correct contract addresses and ABIs are automatically selected based on the network you're connecting to.

```typescript
import { network } from '@co/contracts';

if (network.chainId === 42161) {
  console.log('Connected to Arbitrum mainnet');
} else if (network.chainId === 421614) {
  console.log('Connected to Arbitrum testnet');
}
```

## Error Handling

All contract interactions include proper error handling:

```typescript
import { DCUToken } from '@decleanup/contracts';

async function safeTransfer(signer: ethers.Signer, recipient: string, amount: bigint) {
  try {
    const token = DCUToken.contract.connect(signer);
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