const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const PHXRate = await ethers.getContractFactory("PHXRate");
    const txData = PHXRate.interface.encodeFunctionData("initialize", [
        [
            {
                startTime: parseInt(Date.now() / 1000) + 60 * 60 * 2,
                rate: 100,
            },
            {
                startTime: parseInt(Date.now() / 1000) + 60 * 60 * 4,
                rate: 0,
            },
        ],
    ]);
    await deploy("PHXRate", {
        from: deployer,
        args: [],
        log: true,
        proxy: {
            proxyContract: "Proxy1967",
            proxyArgs: ["{implementation}", txData],
        },
    });
};
module.exports.tags = ["phx_rate"];
module.exports.id = "phx_rate";
