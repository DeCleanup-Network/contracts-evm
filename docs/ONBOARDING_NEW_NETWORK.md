# Onboarding a New Network

This guide explains how to add a new network to the DeCleanup Network contracts system.

## Prerequisites

1. Network details:
   - Chain ID
   - RPC URL
   - Network name (in kebab-case, e.g., `new-network`)
   - Explorer URL (if available)

2. Access to:
   - GitHub repository
   - NPM registry
   - Network's block explorer (if verification is supported)

## Steps to Add a New Network

### 1. Update Network Configuration

Add the new network to the `networks` object in `contracts/scripts/generate-package.ts`:

```typescript
const networks: Networks = {
  "arbitrum-sepolia": {
    chainId: 421614,
    path: "arbitrum-sepolia",
  },
  arbitrum: {
    chainId: 42161,
    path: "arbitrum",
  },
  "new-network": {  // Add your network here
    chainId: YOUR_CHAIN_ID,
    path: "new-network",
  },
};
```

### 2. Add Network to GitHub Workflow

Update `contracts/.github/workflows/deploy-contracts.yml`:

1. Add the network to the workflow inputs:
```yaml
workflow_dispatch:
  inputs:
    network:
      description: 'Network to deploy to (arbitrum-sepolia/arbitrum/new-network)'
      required: true
      default: 'arbitrum-sepolia'
      type: choice
      options:
        - arbitrum-sepolia
        - arbitrum
        - new-network
```

2. Add deployment step:
```yaml
- name: Deploy to New Network
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.network == 'new-network'
  run: npm run deploy:new-network
  env:
    NEW_NETWORK_RPC_URL: ${{ secrets.NEW_NETWORK_RPC_URL }}
    PRIVATE_KEY: ${{ secrets.DEPLOYER_PRIVATE_KEY }}
    EXPLORER_API_KEY: ${{ secrets.EXPLORER_API_KEY }}
```

3. Add verification step:
```yaml
- name: Verify Contracts on New Network
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.network == 'new-network'
  run: npm run verify:all-new-network
  env:
    NEW_NETWORK_RPC_URL: ${{ secrets.NEW_NETWORK_RPC_URL }}
    EXPLORER_API_KEY: ${{ secrets.EXPLORER_API_KEY }}
```

### 3. Add Network-Specific Scripts

1. Add deployment script to `package.json`:
```json
{
  "scripts": {
    "deploy:new-network": "hardhat run scripts/deploy.ts --network new-network",
    "verify:all-new-network": "hardhat run scripts/verify.ts --network new-network"
  }
}
```

2. Add network configuration to `hardhat.config.ts`:
```typescript
const config: HardhatUserConfig = {
  networks: {
    "new-network": {
      url: process.env.NEW_NETWORK_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: YOUR_CHAIN_ID,
    },
  },
};
```

### 4. Add GitHub Secrets

Add the following secrets to your GitHub repository:
- `NEW_NETWORK_RPC_URL`: RPC URL for the new network
- `EXPLORER_API_KEY`: API key for the network's block explorer (if applicable)

### 5. Test the Integration

1. Deploy contracts to the new network:
   - Go to GitHub Actions
   - Select "Deploy Smart Contracts"
   - Choose "new-network" from the network dropdown
   - Run the workflow

2. Verify the deployment:
   - Check the deployment artifacts
   - Verify contracts on the block explorer
   - Test the generated package with the new network

### 6. Update Documentation

1. Update `contracts/docs/CONTRACT_PACKAGE.md` to include the new network
2. Add any network-specific considerations or requirements
3. Update example code to show usage with the new network

## Package Generation

The package generation script (`generate-package.ts`) will automatically:
1. Create a network-specific folder
2. Generate network-specific index files
3. Include the network in the base index files
4. Support the network in the `DCUContracts` class

## Testing

After adding a new network:
1. Deploy contracts to the network
2. Generate the package
3. Test the package with the new network:
```typescript
import { DCUContracts, Networks } from "@decleanup/contracts";

const contracts = new DCUContracts(Networks.NEW_NETWORK);
// Use contracts as needed
```

## Troubleshooting

Common issues and solutions:

1. **Deployment Fails**
   - Check RPC URL and private key
   - Verify network configuration in Hardhat
   - Check gas settings if needed

2. **Verification Fails**
   - Verify explorer API key
   - Check contract constructor arguments
   - Ensure network is supported by the explorer

3. **Package Generation Issues**
   - Check network name format (kebab-case)
   - Verify deployment addresses file
   - Check TypeChain types generation

## Support

If you encounter any issues:
1. Check the existing documentation
2. Review GitHub issues
3. Contact the development team 