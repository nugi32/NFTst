require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Impor dotenv untuk membaca file .env

// Ambil variabel dari file .env
const { ALCHEMY_API_KEY, PRIVATE_KEY } = process.env;

// Validasi variabel lingkungan
if (!ALCHEMY_API_KEY) {
  throw new Error("ALCHEMY_API_KEY is not set in .env file");
}
if (!PRIVATE_KEY) {
  throw new Error("PRIVATE_KEY is not set in .env file");
}

console.log("ALCHEMY_API_KEY:", ALCHEMY_API_KEY);
console.log("PRIVATE_KEY:", PRIVATE_KEY ? "Loaded" : "Not Loaded");

module.exports = {
  solidity: "0.8.28", // Updated to match NFTst.sol
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
    cache: "./cache"
  },
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`, // Gunakan Alchemy URL
      accounts: [PRIVATE_KEY] // Gunakan private key dari .env
    }
  }
};