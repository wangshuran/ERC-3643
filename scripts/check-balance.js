const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("使用账户查询:", deployer.address);

  // 代币合约地址
  const tokenAddress = "0xDC1fF6de2DD774B5f8e5Ef3A143DE65d34D57B10";
  // Alice 钱包地址
  const aliceWalletAddress = "0x27462e7E90af2305c82f63dd2178F7255a4F255e";

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
