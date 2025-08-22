const hre = require("hardhat");

async function main() {
    // 合约地址：替换为你实际部署的Greeter合约地址
    const contractAddress = "0xcB0510e0EC5d63222c8F9FD2D340aF1B9a5b9917";

    // 加载合约实例
    const HelloWord = await hre.ethers.getContractFactory("HelloWord");
    const greeter = await HelloWord.attach(contractAddress);

    console.log(`正在从合约 ${contractAddress} 读取问候语...`);

    // 调用greet()函数（view函数，不消耗gas，无需等待交易确认）
    const currentGreeting = await greeter.greet();
    console.log(`当前合约中的问候语: ${currentGreeting}`);

    console.log("\n监听合约事件（最近3条）:");
    greeter.queryFilter("GreetingSet", -3).then((events) => {
        events.forEach((event, index) => {
            console.log(`事件 ${index + 1}:`);
            console.log(`- 新问候语: ${event.args.newGreeting}`);
            console.log(`- 时间: ${new Date(event.args.timestamp * 1000).toLocaleString()}`);
        });
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("读取合约内容失败:", error);
        process.exitCode = 1;
    });
