const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("使用账户查询:", deployer.address);

  // 代币合约地址
  const tokenAddress = "0xb16C4d8EB5ed178CFDC3461B2b6AeBBc614CA084";
  // Alice 钱包地址
  const aliceWalletAddress = "0x0c528F6BB1eD2064bF48C57cE37359D03931F1F7";

  try {
    // 连接代币合约
    const tokenContract = await ethers.getContractAt("Token", tokenAddress);

    // 调用 balanceOf 方法查询余额
    const aliceBalance = await tokenContract.balanceOf(aliceWalletAddress);

    console.log(`Alice 钱包的代币余额: ${aliceBalance.toString()}`);
    // 如果代币有小数位（如你的部署中是 6 位），可以格式化显示：
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
