import { ethers } from "hardhat";

// deploy a mock open token 
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with address:", deployer.address);

  const MyERC20 = await ethers.getContractFactory("Open");

  const token = await MyERC20.deploy(deployer.address);
  console.log("open deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
