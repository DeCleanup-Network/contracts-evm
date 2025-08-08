<general_rules>
- **Custom Error Handling**: Always use the standardized custom error pattern `CONTRACT__ErrorType(parameters)` instead of string-based require statements. The CONTRACT prefix should match the contract name (e.g., `NFT__`, `REWARD__`, `TOKEN__`, `STORAGE__`). This pattern improves gas efficiency and provides structured error data for frontend applications.

- **Contract Function Development**: Before creating new contract functions, always search the existing contracts in the `/contracts/` directory to check if similar functionality already exists. If found, extend or modify the existing implementation rather than duplicating code.

- **Gas Optimization**: Prioritize gas optimization in all contract implementations. Use efficient data structures, minimize storage operations, and leverage OpenZeppelin's gas-optimized patterns. Run gas comparison scripts using `npm run gas:compare` to measure improvements.

- **Modular Design**: Maintain the modular architecture by keeping contract responsibilities separate. Each contract should have a single, well-defined purpose within the system.

- **Test Coverage Requirements**: All code changes must meet strict coverage thresholds enforced by GitHub Actions:
  - Statements: 85%
  - Branches: 60% 
  - Functions: 80%
  - Lines: 85%

- **Documentation**: Update relevant documentation in the `/docs/` directory when adding new features or modifying existing functionality. Include API documentation and usage examples.
</general_rules>

<repository_structure>
- **Core Architecture**: The repository implements a modular smart contract system with four main contracts:
  - `DCUStorage`: Core storage contract managing token balances, staking, and distribution
  - `DCURewardManager`: Handles reward calculations and distribution logic
  - `DipNft`: ERC-721 NFT contract for Dynamic Impact Products with level progression
  - `DCUToken`: ERC-20 token contract with pre-TGE transfer restrictions

- **Directory Structure**:
  - `/contracts/`: Main Solidity smart contracts
  - `/contracts/interfaces/`: Contract interface definitions for external interactions
  - `/contracts/tokens/`: Token implementation contracts (DCUToken, DipNft, NFTCollection)
  - `/test/`: Comprehensive test suite with TypeScript test files
  - `/test/helpers/`: Test utility functions including custom error matching
  - `/docs/`: Technical documentation, API references, and deployment guides
  - `/scripts/`: Deployment scripts, gas analysis tools, and utility scripts
  - `/ignition/modules/`: Hardhat Ignition deployment modules
  - `/types/`: TypeScript type definitions
  - `/utils/`: Utility functions for metadata generation

- **Configuration Files**: 
  - `hardhat.config.ts`: Hardhat framework configuration with Arbitrum network settings
  - `tsconfig.json`: TypeScript configuration for the project
  - `.github/workflows/`: CI/CD workflows for testing and deployment automation
</repository_structure>

<dependencies_and_installation>
- **Package Manager**: Use npm for dependency management. Always install with the `--legacy-peer-deps` flag to handle peer dependency conflicts: `npm install --legacy-peer-deps`

- **Core Framework**: Built on Hardhat development framework with TypeScript support and Viem integration for modern Ethereum interactions.

- **Base Libraries**: 
  - OpenZeppelin Contracts v5.2.0 for secure, audited smart contract implementations
  - Ethers.js v5.7.2 for blockchain interactions
  - Chai for test assertions with custom error matching extensions

- **Development Tools**:
  - Hardhat toolbox with Viem integration
  - TypeChain for TypeScript contract bindings
  - Solidity Coverage for test coverage reporting
  - Hardhat Gas Reporter for gas usage analysis

- **Network Configuration**: Configured for Arbitrum mainnet and Sepolia testnet deployment. Requires environment variables for RPC URLs and private keys (see `.env.example`).
</dependencies_and_installation>

<testing_instructions>
- **Testing Framework**: Uses Hardhat with Chai assertions and custom error matching helpers located in `/test/helpers/errorMessages.ts`.

- **Test Execution Commands**:
  - `npm test`: Run the complete test suite
  - `npx hardhat test test/[ContractName].test.ts`: Run tests for a specific contract
  - `SOLIDITY_COVERAGE=true npm run test:coverage`: Generate detailed coverage report

- **Custom Error Testing**: The repository includes specialized error matching functionality that handles both string-based errors and custom Solidity errors. Use the imported `expect` from `/test/helpers/setup.ts` for consistent error assertion behavior.

- **Coverage Requirements**: All tests must maintain the following minimum coverage thresholds:
  - Statements: 85%
  - Branches: 60%
  - Functions: 80%
  - Lines: 85%

- **Test Structure**: Each contract has a corresponding test file following the naming pattern `[ContractName].test.ts`. Tests should cover all public functions, error conditions, access controls, and edge cases.

- **Continuous Integration**: GitHub Actions automatically runs tests and coverage checks on pull requests to the master branch. Pull requests failing coverage thresholds will be blocked from merging.
</testing_instructions>

<pull_request_formatting>
</pull_request_formatting>
