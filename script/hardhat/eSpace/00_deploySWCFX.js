const { ethers, upgrades } = require("hardhat");
const { address } = require("js-conflux-sdk");

async function main() {
    // await deploySWCFX();
    // await upgradeSWCFX();
    await setupSWCFX();
}

main();

async function deploySWCFX() {
    const SWCFX = await ethers.getContractFactory("SWCFX");
    const sWCFX = await upgrades.deployProxy(SWCFX, [
        "PoS Wrapped CFX",
        "sWCFX",
    ]);
    await sWCFX.deployed();
    console.log("sWCFX deployed to:", sWCFX.address);
}

async function upgradeSWCFX() {
    const SWCFX = await ethers.getContractFactory("SWCFX");
    const swcfx = await upgrades.upgradeProxy(process.env.SWCFX, SWCFX);
    console.log("SWCFX upgraded");
}

async function setupSWCFX() {
    const swcfx = await ethers.getContractAt("SWCFX", process.env.SWCFX);

    let tx = await swcfx.setCoreBridge(
        address.cfxMappedEVMSpaceAddress(process.env.SWCFX_BRIDGE)
    );
    await tx.wait();

    let tx2 = await swcfx.setLiquidPool(process.env.LIQUIDITY_POOL);
    await tx2.wait();
    console.log("Finished");
}
