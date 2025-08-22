const hre = require("hardhat");

async function main() {
  // 部署合约
  const HelloWord = await hre.ethers.getContractFactory("HelloWord");
  // 部署合约
  const greeter = await HelloWord.deploy("Hello, Hardhat!");

  // 等待合约部署完成
  await greeter.deployed();

  // 获取合约地址
  console.log(`部署成功，合约地址：${greeter.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
