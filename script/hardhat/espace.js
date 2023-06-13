const { ethers } = require("hardhat");
const { address } = require("js-conflux-sdk");

async function main() {
    // await deployLiquidityPool();
    // await setupLiquidityPool();
    // await deployTreasury();
    // await setupTreasury();
    // await transferFromTreasury();
    // await transferPHX("0x7deFad05B632Ba2CeF7EA20731021657e20a7596", 3000);
    // await deployCCFX();
    // await setupCCFX();
    // await deployFarmingPool();
    // await setupFarmingPool();
    // await upgradeCCFX();
    // await setFarmingPoolReward();
    // await upgradeFarmingController();
    // await deployPHXRate();
    // await transferPHX(process.env.FARMING_CONTROLLER, "3650000");
    // await deployLP();
    // await setFarmingControllerPhxRate();
    await transferPHX("0x7deFad05B632Ba2CeF7EA20731021657e20a7596", 1000000);
}

main().catch(console.log);

async function deployLP() {
    const Contract = await ethers.getContractFactory("PHX");
    const contract = await Contract.deploy(process.env.TREASURY);
    await contract.deployed();
    console.log("PHX deployed to:", contract.address);
}

async function deployPHXRate() {
    const Contract = await ethers.getContractFactory("PHXRate");
    const contract = await Contract.deploy();
    await contract.deployed();

    const txData = contract.interface.encodeFunctionData("initialize", [
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

    console.log(txData);

    const Proxy1967 = await ethers.getContractFactory("Proxy1967");
    const proxy = await Proxy1967.deploy(contract.address, txData);
    await proxy.deployed();
    console.log("PHXRate deployed to:", proxy.address);
}

async function setFarmingControllerPhxRate() {
    const contract = await ethers.getContractAt(
        "FarmingController",
        process.env.FARMING_CONTROLLER
    );

    /* let tx = await contract.setPhxRate(process.env.PHX_RATE);
    await tx.wait();
    console.log("setPhxRate done"); */

    let tx = await contract.add(
        1000,
        process.env.LP,
        parseInt(Date.now() / 1000),
        true
    );
    await tx.wait();
}

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

async function upgradeFarmingController() {
    const Contract = await ethers.getContractFactory("FarmingController");
    const contract = await Contract.deploy();
    await contract.deployed();
    console.log("FARMING_CONTROLLER impl deployed to:", contract.address);

    const proxy1967 = await ethers.getContractAt(
        "Proxy1967",
        process.env.FARMING_CONTROLLER
    );
    const tx = await proxy1967.upgradeTo(contract.address);
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

async function transferFromTreasury(to, amount) {
    const PHXTreasury = await ethers.getContractAt(
        "PHXTreasury",
        process.env.TREASURY
    );
    const tx = await PHXTreasury.transfer(
        to,
        ethers.utils.parseEther(amount.toString())
    );
    await tx.wait();
    console.log("PHXTreasury transfer");
}

async function transferPHX(to, amount) {
    const PHX = await ethers.getContractAt("PHX", process.env.LP);
    const tx = await PHX.transfer(
        to,
        ethers.utils.parseEther(amount.toString())
    );
    await tx.wait();
}
