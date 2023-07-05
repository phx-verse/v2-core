const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const phxRate = await ethers.getContract("PHXRate");
    const voting = await ethers.getContract("VotingEscrow");

    const Contract = await ethers.getContractFactory("FarmingController");
    const txData = Contract.interface.encodeFunctionData("initialize", [
        voting.address,
        phxRate.address,
        process.env.PHX,
        parseInt(Date.now() / 1000),
        process.env.LP1,
    ]);
    await deploy("FarmingController", {
        from: deployer,
        args: [],
        log: true,
        proxy: {
            proxyContract: "Proxy1967",
            proxyArgs: ["{implementation}", txData],
        },
    });
};
module.exports.tags = ["FarmingController"];
module.exports.id = "FarmingController";
