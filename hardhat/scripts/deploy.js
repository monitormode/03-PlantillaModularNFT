// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

async function main() {

  const Whitelist = await hre.ethers.getContractFactory("Whitelist");
  const whitelist = await Whitelist.deploy(200);
  await whitelist.deployed();

  const PunchingERC721 = await hre.ethers.getContractFactory("PunchingPacoERC721Redux");
  const punchingERC721 = await PunchingERC721.deploy(whitelist.address, "ipfs://punchingPacoIPFS/");
  await punchingERC721.deployed();

  const PunchingERC20 = await hre.ethers.getContractFactory("PunchingPacoTokenERC20");
  const punchingERC20 = await PunchingERC20.deploy();
  await punchingERC20.deployed();

  const PunchingStaking = await hre.ethers.getContractFactory("PunchingPacoStaking")
  const punchingStaking = await PunchingStaking.deploy(punchingERC721.address, punchingERC20.address);
  await punchingStaking.deployed();


  console.log("Whitelist deploy address       : " + whitelist.address)
  console.log("PunchingERC721 deploy address  : " + punchingERC721.address)
  console.log("PunchingERC20 deploy address   : " + punchingERC20.address)
  console.log("PunchingStaking deploy address : " + punchingStaking.address)
  // console.log(
  //   `Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
