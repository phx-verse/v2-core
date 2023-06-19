const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const PHXRate = await ethers.getContractFactory("PHXRate");
    const txData = PHXRate.interface.encodeFunctionData("initialize", [
        [
            {
                startTime: parseInt(Date.now() / 1000) + 60 * 60 * 1,
                rate: 115740740740740740n, // one year 365w phx
            },
            {
                startTime: parseInt(Date.now() / 1000) + 60 * 60 * 24 * 365,
                rate: 0n,
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
