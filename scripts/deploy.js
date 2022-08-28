// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  //Constructor arguement values
  const subscriptionId = 385;
  const coordinator = "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D";
  const keyHash = "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15";
  const callbackGasLimit = 2500000;
  const numConfirmations = 3;
  const numWords = 4;

  const sentimentFactory = await hre.ethers.getContractFactory("Sentiment");
  const sentimentContract = await sentimentFactory.deploy(
    subscriptionId,
    coordinator,
    keyHash,
    callbackGasLimit,
    numConfirmations,
    numWords
  );
  await sentimentContract.deployed();
  console.log(`Contract deployed to: ${sentimentContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
