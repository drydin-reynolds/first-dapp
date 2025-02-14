import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners(); // Gets first account
  console.log("Deploying contracts with account:", deployer.address);

  const MIN_STAKE = ethers.parseEther("0.1");
  
  // Deploy Mock Token (if needed)
  const Token = await ethers.getContractFactory("MockToken");
  const token = await Token.deploy();
  console.log("Token deployed to:", await token.getAddress());

  // Deploy JobBoard
  const JobBoard = await ethers.getContractFactory("JobBoard");
  const jobBoard = await JobBoard.deploy(
    await token.getAddress(), // Use token address
    MIN_STAKE
  );

  console.log("JobBoard deployed to:", await jobBoard.getAddress());
}

main();
