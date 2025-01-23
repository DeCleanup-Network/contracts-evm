// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

const DCU = buildModule("DCU", (m) => {
  // Define the initial supply parameter (default: 1,000,000 tokens)
  const initialSupply = m.getParameter("initialSupply", parseEther("1000000"));

  // Deploy the MyToken contract with the initial supply
  const dcuToken = m.contract("DeCleanup", [initialSupply]);

  return { dcuToken };
});

export default DCU;