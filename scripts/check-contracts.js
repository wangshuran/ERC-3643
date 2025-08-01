const { ethers } = require("hardhat");

async function main() {
  // 连接到 Ganache 网络
  const [deployer] = await ethers.getSigners();
  console.log("使用账户查询:", deployer.address);

  // 合约地址列表
  const contracts = [
    { name: "合约", address: "0x5ffd3ca2DFaC8Af6315ACC86Adc01a336eD0f2Dc" },
  ];

  // 遍历验证合约
  for (const contract of contracts) {
    try {
      // 检查地址是否有合约代码
      const code = await ethers.provider.getCode(contract.address);
      if (code === "0x") {
        console.log(
          `❌ ${contract.name} (${contract.address}): 未部署或地址无效`
        );
        continue;
      }

      // 调用一个通用方法
      const contractInstance = await ethers.getContractAt(
        // 替换为合约的名称或ABI（如果知道）
        "Token", // 以代币合约为例，其他合约需对应修改
        contract.address
      );

      // 调用合约方法
      const name = await contractInstance.name();
      console.log(
        `✅ ${contract.name} (${contract.address}): 已部署，名称: ${name}`
      );
    } catch (error) {
      console.log(
        `⚠️ ${contract.name} (${
          contract.address
        }): 验证失败，错误: ${error.message.slice(0, 50)}`
      );
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
