const { ethers } = require("hardhat");
const { address } = require("js-conflux-sdk");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy("CCFX", {
        from: deployer,
        args: [],
        log: true,
        proxy: {
            proxyContract: "Proxy1967",
            proxyArgs: ["{implementation}", "0x8129fc1c"],
        },
    });

    const ccfx = await ethers.getContract("CCFX");

    console.log("setting ccfx core bridge");
    const tx = await ccfx.setCoreBridge(
        address.cfxMappedEVMSpaceAddress(process.env.CCFX_BRIDGE)
    );
    await tx.wait();
};
module.exports.tags = ["CCFX"];
module.exports.id = "ccfx";
