const { ethers } = require("hardhat");

async function main() {
  // 1. 配置转账参数
  const tokenAddress = "0xDC1fF6de2DD774B5f8e5Ef3A143DE65d34D57B10"; // 代币合约地址
  const fromAddress = "0x064cF0f5CF2360b7a013F3953f3DB4A3D9Ec16AC"; // Alice 钱包地址
  const toAddress = "0x27462e7E90af2305c82f63dd2178F7255a4F255e"; // Bob 钱包地址
  const amount = 100; // 转账数量

  // 2. 遍历所有签名者，找到 Alice 的签名
  const signers = await ethers.getSigners();
  let aliceSigner = null;
  for (const signer of signers) {
    if (signer.address.toLowerCase() === fromAddress.toLowerCase()) {
      aliceSigner = signer;
      break;
    }
  }
  if (!aliceSigner) {
    throw new Error(`未找到 Alice 的签名者，地址: ${fromAddress}`);
  }
  console.log("使用 Alice 签名者:", aliceSigner.address);

  // 3. 连接代币合约
  const tokenContract = await ethers.getContractAt("Token", tokenAddress);
  console.log("已连接代币合约:", tokenContract.address);

  // 4. 检查转账前余额
  const aliceBalanceBefore = await tokenContract.balanceOf(fromAddress);
  const bobBalanceBefore = await tokenContract.balanceOf(toAddress);
  console.log(`\n转账前 - Alice 余额: ${aliceBalanceBefore.toString()}`);
  console.log(`转账前 - Bob 余额: ${bobBalanceBefore.toString()}`);

  // 5. 先授权（approve）
  const approveTx = await tokenContract.connect(aliceSigner).approve(
    aliceSigner.address, // 授权给 Alice 自己
    amount
  );
  await approveTx.wait();
  console.log("\n授权完成，交易哈希:", approveTx.hash);

  // 6. 执行 transferFrom 转账
  const transferTx = await tokenContract.connect(aliceSigner).transferFrom(
    fromAddress,
    toAddress,
    amount
  );
  await transferTx.wait();
  console.log("转账完成，交易哈希:", transferTx.hash);

  // 7. 检查转账后余额
  const aliceBalanceAfter = await tokenContract.balanceOf(fromAddress);
  const bobBalanceAfter = await tokenContract.balanceOf(toAddress);
  console.log(`\n转账后 - Alice 余额: ${aliceBalanceAfter.toString()}`);
  console.log(`转账后 - Bob 余额: ${bobBalanceAfter.toString()}`);

  console.log("\n转账成功！");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("转账失败:", error.message);
    process.exit(1);
  });
