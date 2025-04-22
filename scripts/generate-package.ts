import * as fs from "fs";
import * as path from "path";
import { ethers } from "hardhat";

async function main() {
  // Read deployment addresses
  const deploymentsPath = path.join(
    __dirname,
    "deployed_addresses_arbitrum.json"
  );
  const deployments = JSON.parse(fs.readFileSync(deploymentsPath, "utf8"));

  // Create package directory
  const packageDir = path.join(__dirname, "../package");
  if (!fs.existsSync(packageDir)) {
    fs.mkdirSync(packageDir);
  }

  // Create package.json
  const packageJson = {
    name: "@decleanup/contracts",
    version: process.env.npm_package_version || "1.0.0",
    description: "DeCleanup Network Smart Contracts",
    main: "index.js",
    types: "index.d.ts",
    files: ["*.js", "*.d.ts", "artifacts/**/*.json", "typechain/**/*.ts"],
    repository: {
      type: "git",
      url: "git+https://github.com/decleanup/DeCleanup_Network.git",
    },
    keywords: ["ethereum", "arbitrum", "smart-contracts"],
    author: "DeCleanup Network",
    license: "MIT",
    bugs: {
      url: "https://github.com/decleanup/DeCleanup_Network/issues",
    },
    homepage: "https://github.com/decleanup/DeCleanup_Network#readme",
    dependencies: {
      ethers: "^6.0.0",
      "@typechain/ethers-v6": "^0.4.0",
      "@typechain/hardhat": "^7.0.0",
    },
  };

  fs.writeFileSync(
    path.join(packageDir, "package.json"),
    JSON.stringify(packageJson, null, 2)
  );

  // Create index.ts and index.d.ts
  const contracts = [
    "DCUToken",
    "RewardLogic",
    "DCUAccounting",
    "DCUStorage",
    "DCURewardManager",
    "DipNft",
  ];

  let indexTs = "";
  let indexDTs = "";

  // Copy TypeChain types
  const typechainDir = path.join(__dirname, "../typechain-types");
  const packageTypechainDir = path.join(packageDir, "typechain");
  if (!fs.existsSync(packageTypechainDir)) {
    fs.mkdirSync(packageTypechainDir, { recursive: true });
  }

  // Copy all TypeChain files
  const copyTypechainFiles = (src: string, dest: string) => {
    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);
      if (entry.isDirectory()) {
        fs.mkdirSync(destPath, { recursive: true });
        copyTypechainFiles(srcPath, destPath);
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  };

  copyTypechainFiles(typechainDir, packageTypechainDir);

  for (const contract of contracts) {
    const artifactPath = path.join(
      __dirname,
      "../artifacts/contracts",
      contract + ".sol",
      contract + ".json"
    );
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

    // Create contract-specific files
    const contractDir = path.join(packageDir, "artifacts", contract);
    if (!fs.existsSync(contractDir)) {
      fs.mkdirSync(contractDir, { recursive: true });
    }

    // Save ABI
    fs.writeFileSync(
      path.join(contractDir, "abi.json"),
      JSON.stringify(artifact.abi, null, 2)
    );

    // Save bytecode
    fs.writeFileSync(
      path.join(contractDir, "bytecode.json"),
      JSON.stringify({ bytecode: artifact.bytecode }, null, 2)
    );

    // Add to index files with TypeChain types
    indexTs += `import { ${contract} as ${contract}Type } from './typechain/types/${contract}';
export const ${contract} = {
  address: '${deployments[contract]}',
  abi: require('./artifacts/${contract}/abi.json'),
  bytecode: require('./artifacts/${contract}/bytecode.json').bytecode,
  network: '${deployments.network}',
  chainId: ${deployments.chainId},
  contract: ${contract}Type
};\n\n`;

    indexDTs += `import { ${contract} as ${contract}Type } from './typechain/types/${contract}';
export const ${contract}: {
  address: string;
  abi: any[];
  bytecode: string;
  network: string;
  chainId: number;
  contract: typeof ${contract}Type;
};\n\n`;
  }

  // Add network info
  indexTs += `export const network = {
  name: '${deployments.network}',
  chainId: ${deployments.chainId},
  deployedAt: '${deployments.deployedAt}'
};\n`;

  indexDTs += `export const network: {
  name: string;
  chainId: number;
  deployedAt: string;
};\n`;

  // Write index files
  fs.writeFileSync(path.join(packageDir, "index.ts"), indexTs);
  fs.writeFileSync(path.join(packageDir, "index.d.ts"), indexDTs);

  // Compile TypeScript
  require("child_process").execSync("npx tsc index.ts", { cwd: packageDir });

  console.log("Package generated successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
