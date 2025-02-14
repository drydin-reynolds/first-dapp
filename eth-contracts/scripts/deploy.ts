import { ethers } from "hardhat";

async function main() {
  // Gets the deployer address
  const [deployer] = await ethers.getSigners();
  console.log("👷 Deployer address:", deployer.address);

  // Compile the contract
  const JobBoard = await ethers.getContractFactory("JobBoard");
  
  // Deploy the contract (Change these values as needed)
  const jobBoard = await JobBoard.deploy(
    "0xYourTokenAddressHere",  // Replace with your token address
    ethers.parseEther("0.1")   // Minimum stake value
  );

  // Wait for deployment confirmation
  await jobBoard.waitForDeployment();
  const contractAddress = await jobBoard.getAddress();
  
  console.log("✅ JobBoard deployed to:", contractAddress);
}

// Execute and Handle Errors
main().catch((error) => {
  console.error("⚠️ Deployment failed:", error);
  process.exitCode = 1;
});
