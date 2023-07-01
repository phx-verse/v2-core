const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const PHXRate = await ethers.getContractFactory("PHXRate");
    const startTime = parseInt(Date.UTC(2023, 6, 3, 8, 0, 0) / 1000); // 2023.7.3 08:00 (UTC+0)
    const txData = PHXRate.interface.encodeFunctionData("initialize", [
        [
            {
                startTime: parseInt(Date.now() / 1000) + 60 * 5,
                rate: 0n,
            },
            {
                startTime: startTime,
                rate: 190258751902587519n, // 4 year 2400w phx
            },
            {
                startTime: startTime + 60 * 60 * 24 * 365 * 4,
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
