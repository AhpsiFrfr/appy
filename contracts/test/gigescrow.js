const { expect } = require("chai");

describe("GigEscrow", function () {
  it("should deploy", async function () {
    const GigEscrow = await ethers.getContractFactory("GigEscrow");
    const escrow = await GigEscrow.deploy();
    await escrow.waitForDeployment();
    expect(await escrow.feesAccrued()).to.equal(0);
  });
});
