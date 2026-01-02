const hre = require("hardhat");

async function main() {
  // Dapatkan factory kontrak
  const NFTst = await hre.ethers.getContractFactory("NFTst");
  
  // Deploy kontrak
  const nftst = await NFTst.deploy();

  // Tunggu hingga kontrak selesai di-deploy
  await nftst.waitForDeployment();

  // Dapatkan alamat kontrak
  const contractAddress = await nftst.getAddress();
  console.log("NFTst deployed to:", contractAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});