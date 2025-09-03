const hre = require("hardhat");

async function main() {
    // 1. 配置参数
    const contractAddress = "0x7Df21351Cec71acc12125da2CA2Db372414e27e1";
    const newGreeting = "Hello, Blockchain Learner!";

    // 2. 加载合约实例
    const HelloWord = await hre.ethers.getContractFactory("HelloWord");
    const greeter = await HelloWord.attach(contractAddress);

    console.log(`正在向合约 ${contractAddress} 设置新问候语: ${newGreeting}`);

    // 3. 调用setGreeting函数（会产生交易，需要支付gas）
    const tx = await greeter.setGreeting(newGreeting);
    console.log(`交易已发送，哈希值: ${tx.hash}`);

    // 4. 等待交易被区块确认（重要：确保修改已上链）
    console.log("等待交易确认...");
    await tx.wait();
    console.log("交易已确认！");

    // 5. 验证修改结果
    const updatedGreeting = await greeter.greet();
    console.log(`修改后的值: ${updatedGreeting}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("设置问候语失败:", error);
        process.exitCode = 1;
    });
