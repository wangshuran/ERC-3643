import "@xyrusworx/hardhat-solidity-json";
import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import "@nomiclabs/hardhat-solhint";
import "@primitivefi/hardhat-dodoc";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  dodoc: {
    runOnCompile: false,
    debugMode: true,
    outputDir: "./docgen",
    freshOutput: true,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:7545",
      chainId: 1337,
      // accounts: ["0x86dc457d06f1c7cb02174452b9594bf7ec156be2d22c2721ae50ab5916cbdd3a"]
      // accounts: {
      //   mnemonic: "test test test test test test test test test test test junk",
      //   accountsBalance: "10000000000000000000000", // 10000 ETH
      //   count: 20 // 确保有足够多的账户
      // }
    },
    // 本地测试网（默认内置）
    hardhat: {},
  },
};

export default config;
