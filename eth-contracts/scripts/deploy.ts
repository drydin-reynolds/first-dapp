// scripts/deploy.ts (fixed)
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  // Deploy Token
  const Token = await ethers.getContractFactory("Lock");
  const token = await Token.deploy();
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();

  // Deploy JobBoard (1 argument + overrides)
  const JobBoard = await ethers.getContractFactory("JobBoard");
  const jobBoard = await JobBoard.deploy(
    tokenAddress,  // Single constructor argument
    {}             // Overrides object
  );
  
  console.log("✅ JobBoard deployed to:", await jobBoard.getAddress());
}

main().catch((error) => {
  console.error("⚠️ Deployment failed:", error);
  process.exit(1);
});
