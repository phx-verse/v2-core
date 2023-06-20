const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy("FarmingPool", {
        from: deployer,
        args: [],
        log: true,
        proxy: {
            proxyContract: "Proxy1967",
            proxyArgs: ["{implementation}", "0x8129fc1c"],
        },
    });

    const farmingPool = await ethers.getContract("FarmingPool");
    const ccfx = await ethers.getContract("CCFX");

    console.log("setting farming_pool phx and ccfx");
    let tx = await farmingPool.setCCFX(ccfx.address);
    await tx.wait();

    tx = await farmingPool.setPHX(process.env.PHX);
    await tx.wait();
};
module.exports.tags = ["FarmingPool"];
module.exports.id = "FarmingPool";
