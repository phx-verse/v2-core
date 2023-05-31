const { ethers } = require("hardhat");
const { address } = require("js-conflux-sdk");

async function main() {
    // await deployLiquidityPool();
    // await setupLiquidityPool();
    // await deployTreasury();
    // await deployPHX();
    // await setupTreasury();
    // await transferFromTreasury();
    // await transferPHX();
    // await deployCCFX();
    // await setupCCFX();
    // await deployFarmingPool();
    // await setupFarmingPool();
    // await upgradeCCFX();

    await setFarmingPoolReward();
}

main().catch(console.log);

/* async function deployCCFX() {
    const CCFX = await ethers.getContractFactory("CCFX");
    const cCFX = await CCFX.deploy();
    await cCFX.deployed();
    console.log("CCFX impl deployed to:", cCFX.address);

    const Proxy1967 = await ethers.getContractFactory("Proxy1967");
    const proxy = await Proxy1967.deploy(cCFX.address, "0x8129fc1c");
    await proxy.deployed();
    console.log("CCFX deployed to:", proxy.address);
}

async function setupCCFX() {
    const cCFX = await ethers.getContractAt("CCFX", process.env.CCFX);

    let tx = await cCFX.setCoreBridge(
        address.cfxMappedEVMSpaceAddress(process.env.CCFX_BRIDGE)
    );
    await tx.wait();

    let tx2 = await cCFX.setFarmingPool(process.env.FARMING_POOL);
    await tx2.wait();
    console.log("Finished");
} */

async function upgradeCCFX() {
    const CCFX = await ethers.getContractFactory("CCFX");
    const cCFX = await CCFX.deploy();
    await cCFX.deployed();
    console.log("CCFX impl deployed to:", cCFX.address);

    const proxy1967 = await ethers.getContractAt("Proxy1967", process.env.CCFX);
    const tx = await proxy1967.upgradeTo(cCFX.address);
    await tx.wait();
    console.log("Finished");
}

/* async function deployFarmingPool() {
    const FarmingPool = await ethers.getContractFactory("FarmingPool");
    const farmingPool = await FarmingPool.deploy();
    await farmingPool.deployed();
    console.log("FarmingPool impl deployed to:", farmingPool.address);

    const Proxy1967 = await ethers.getContractFactory("Proxy1967");
    const proxy = await Proxy1967.deploy(farmingPool.address, "0x8129fc1c");
    await proxy.deployed();
    console.log("FarmingPool deployed to:", proxy.address);
}

async function setupFarmingPool() {
    const farmingPool = await ethers.getContractAt(
        "FarmingPool",
        process.env.FARMING_POOL
    );

    let tx = await farmingPool.setPHX(process.env.PHX);
    await tx.wait();

    let tx2 = await farmingPool.setCCFX(process.env.CCFX);
    await tx2.wait();
    console.log("Finished");
} */

async function setFarmingPoolReward() {
    const farmingPool = await ethers.getContractAt(
        "FarmingPool",
        process.env.FARMING_POOL
    );

    const duration = 3600 * 24 * 365;
    const amount = 3650000;
    let tx = await farmingPool.setRewardsDuration(duration);
    await tx.wait();

    await transferPHX(process.env.FARMING_POOL, amount.toString());

    let tx2 = await farmingPool.setRewardAmount(
        ethers.utils.parseEther(amount.toString())
    );
    await tx2.wait();

    console.log("setFarmingPoolReward finished");
}

/* async function deployLiquidityPool() {
    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    const liquidityPool = await LiquidityPool.deploy();
    await liquidityPool.deployed();
    console.log("LiquidityPool impl deployed to:", liquidityPool.address);

    const Proxy1967 = await ethers.getContractFactory("Proxy1967");
    const proxy = await Proxy1967.deploy(liquidityPool.address, "0x8129fc1c");
    await proxy.deployed();
    console.log("LiquidityPool deployed to:", proxy.address);
}

async function setupLiquidityPool() {
    const liquidityPool = await ethers.getContractAt(
        "LiquidityPool",
        process.env.LIQUIDITY_POOL
    );

    let tx = await liquidityPool.setSWCFX(process.env.SWCFX);
    await tx.wait();

    console.log("Finished");
} */

/* async function deployTreasury() {
    const PHXTreasury = await ethers.getContractFactory("PHXTreasury");
    const treasury = await PHXTreasury.deploy();
    await treasury.deployed();
    console.log("PHXTreasury deployed to:", treasury.address);
}

async function setupTreasury() {
    const PHXTreasury = await ethers.getContractAt(
        "PHXTreasury",
        process.env.TREASURY
    );
    const tx = await PHXTreasury.setPhx(process.env.PHX);
    await tx.wait();
    console.log("PHXTreasury setup PHX address");
} */

/* async function transferFromTreasury() {
    const PHXTreasury = await ethers.getContractAt(
        "PHXTreasury",
        process.env.TREASURY
    );
    const tx = await PHXTreasury.transfer(
        "0x14273e1953f2d514a6e9f801b9b506a167xxxxxx",
        ethers.utils.parseEther("700000")
    );
    await tx.wait();
    console.log("PHXTreasury transfer");
} */

async function transferPHX(to, amount) {
    const PHX = await ethers.getContractAt("PHX", process.env.PHX);
    const tx = await PHX.transfer(
        to,
        ethers.utils.parseEther(amount.toString())
    );
    await tx.wait();
}

/* async function deployPHX() {
    const PHX = await ethers.getContractFactory("PHX");
    const phx = await PHX.deploy(process.env.TREASURY);
    await phx.deployed();
    console.log("PHX deployed to:", phx.address);
} */
