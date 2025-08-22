const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("使用账户查询:", deployer.address);

  // 代币合约地址
  const tokenAddress = "0x7F0417b4314380D09e157c5c737CbC26Ad8cd74b";
  // Alice 钱包地址
  const aliceWalletAddress = "0xab598391CF668b62f4D2fCF5F7c80F3b2cEf5b82";

  try {
    // 连接代币合约
    const tokenContract = await ethers.getContractAt("Token", tokenAddress);

    // 调用 balanceOf 方法查询余额
    const aliceBalance = await tokenContract.balanceOf(aliceWalletAddress);

    console.log(`Alice 钱包的代币余额: ${aliceBalance.toString()}`);
    console.log(`格式化后余额: ${ethers.utils.formatUnits(aliceBalance, 6)}`);
  } catch (error) {
    console.error("查询余额失败:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
