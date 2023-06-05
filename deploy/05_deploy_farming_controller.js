const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const phx = await ethers.getContract("PHX");
    const phxRate = await ethers.getContract("PHXRate");
    const voting = await ethers.getContract("VotingEscrow");

    const Contract = await ethers.getContractFactory("FarmingController");
    const txData = Contract.interface.encodeFunctionData("initialize", [
        voting.address,
        phxRate.address,
        phx.address,
        parseInt(Date.now() / 1000),
        phx.address, // TODO: use real LP token address
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
