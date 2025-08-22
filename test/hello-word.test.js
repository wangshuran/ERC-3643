const { expect } = require("chai");

describe("HelloWord", function () {
  it("Hi, dazhuang", async function () {
    const Greeter = await ethers.getContractFactory("HelloWord");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    await greeter.setGreeting("Hola, dazhuang!");
    expect(await greeter.greet()).to.equal("Hola, dazhuang!");
  });
});
