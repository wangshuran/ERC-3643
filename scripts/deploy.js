const {
  deployFullSuiteFixture,
} = require("../test/fixtures/deploy-full-suite.fixture.ts");

async function main() {
  const deployment = await deployFullSuiteFixture();

  console.log(deployment);
  console.log("\n~~ 账户信息 ~~");
  console.log("部署者: ", deployment.accounts.deployer.address);
  console.log("代币发行方: ", deployment.accounts.tokenIssuer.address);
  console.log("代币代理: ", deployment.accounts.tokenAgent.address);
  console.log("代币管理员: ", deployment.accounts.tokenAdmin.address);
  console.log("声明发行方: ", deployment.accounts.claimIssuer.address);
  console.log(
    "声明发行方签名密钥: ",
    deployment.accounts.claimIssuerSigningKey.address
  );
  console.log("Alice 操作密钥: ", deployment.accounts.aliceActionKey.address);
  console.log("Alice 钱包: ", deployment.accounts.aliceWallet.address);
  console.log("Bob 钱包: ", deployment.accounts.bobWallet.address);
  console.log("Charlie 钱包: ", deployment.accounts.charlieWallet.address);
  console.log("David 钱包: ", deployment.accounts.davidWallet.address);
  console.log("其他钱包: ", deployment.accounts.anotherWallet.address);
  console.log("\n~~ 身份信息 ~~");
  console.log("Alice 身份: ", deployment.identities.aliceIdentity.address);
  console.log("Bob 身份: ", deployment.identities.bobIdentity.address);
  console.log("Charlie 身份: ", deployment.identities.charlieIdentity.address);
  console.log("\n~~ 合约套件 ~~");
  console.log("声明发行方合约: ", deployment.suite.claimIssuerContract.address);
  console.log("声明主题注册表: ", deployment.suite.claimTopicsRegistry.address);
  console.log(
    "身份注册存储: ",
    deployment.suite.identityRegistryStorage.address
  );
  console.log("基础合规合约: ", deployment.suite.basicCompliance.address);
  console.log("身份注册表: ", deployment.suite.identityRegistry.address);
  console.log("代币OID: ", deployment.suite.tokenOID.address);
  console.log("代币合约: ", deployment.suite.token.address);
  console.log("\n--- --- --- --- ---");
  console.log("部署完成!");
}

main()
  .then(() => {
    console.log("部署完成!");
    // 让程序自然退出，状态码为 0（成功）
  })
  .catch((error) => {
    console.error(error);
    // 设置退出码为 1（错误），但不直接调用 process.exit()
    process.exitCode = 1;
  });
