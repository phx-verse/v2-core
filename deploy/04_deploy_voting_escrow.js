const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const phx = await ethers.getContract("PHX");
    const Contract = await ethers.getContractFactory("VotingEscrow");
    const txData = Contract.interface.encodeFunctionData("initialize", [
        "PHXVoting",
        "PHXV",
        18,
        phx.address,
    ]);
    await deploy("VotingEscrow", {
        from: deployer,
        args: [],
        log: true,
        proxy: {
            proxyContract: "Proxy1967",
            proxyArgs: ["{implementation}", txData],
        },
    });
};
module.exports.tags = ["VotingEscrow"];
module.exports.id = "VotingEscrow";
