const { ethers } = require("hardhat");

async function main() {
  try {
    console.log("Starting deployment to Core Blockchain...");
    
    // Get the contract factory
    const RealEstateTokenization = await ethers.getContractFactory("RealEstateTokenization");
    
    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);
    
    // Get account balance
    const balance = await deployer.getBalance();
    console.log("Account balance:", ethers.utils.formatEther(balance), "CORE");
    
    // Deploy the contract
    console.log("Deploying RealEstateTokenization contract...");
    const realEstateTokenization = await RealEstateTokenization.deploy();
    
    // Wait for deployment to complete
    await realEstateTokenization.deployed();
    
    console.log("✅ RealEstateTokenization contract deployed successfully!");
    console.log("Contract address:", realEstateTokenization.address);
    console.log("Transaction hash:", realEstateTokenization.deployTransaction.hash);
    console.log("Block number:", realEstateTokenization.deployTransaction.blockNumber);
    
    // Wait for a few confirmations
    console.log("Waiting for block confirmations...");
    await realEstateTokenization.deployTransaction.wait(3);
    console.log("✅ Contract confirmed on blockchain");
    
    // Verify contract details
    const owner = await realEstateTokenization.owner();
    const propertyCounter = await realEstateTokenization.propertyCounter();
    const totalValueLocked = await realEstateTokenization.totalValueLocked();
    
    console.log("\n📋 Contract Details:");
    console.log("Owner:", owner);
    console.log("Property Counter:", propertyCounter.toString());
    console.log("Total Value Locked:", ethers.utils.formatEther(totalValueLocked), "CORE");
    
    console.log("\n🎉 Deployment completed successfully!");
    console.log("Network: Core Testnet");
    console.log("Chain ID: 1114");
    
  } catch (error) {
    console.error("❌ Deployment failed:");
    console.error(error.message);
    process.exit(1);
  }
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment script failed:");
    console.error(error);
    process.exit(1);
  });
