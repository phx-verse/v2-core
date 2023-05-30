const hre = require("hardhat");
const {
    conflux, // The Conflux instance
} = hre;
const { logReceipt } = require("./init");

const InitializerSig = "0x8129fc1c";

async function main() {
    const [account] = await conflux.getSigners();

    // await deploySWCFXBridge(account, 0);
    // await setupSWCFXBridge(account);

    // await deployPoSOracle(account);

    // await deployCCFXBridge(account);

    await setupCCFXBridge(account);

    // await upgradeCCFXBridge(account);
}

main().catch(console.log);

async function deploySWCFXBridge(account, value = 0) {
    let addr = await deployContract("SWCFXBridge", account, 0);
    await deployContract("Proxy1967", account, 0, addr, InitializerSig);
}

async function setupSWCFXBridge(account) {
    const contract = await conflux.getContractAt(
        "SWCFXBridge",
        process.env.SWCFX_BRIDGE
    );

    let receipt = await contract
        .setPosPool(process.env.POS_POOL_POW_ADDRESS)
        .sendTransaction({
            from: account.address,
        })
        .executed();

    let receipt2 = await contract
        .setESpacePool(process.env.SWCFX)
        .sendTransaction({
            from: account.address,
        })
        .executed();

    console.log("Finished");
}

async function upgradeSWCFXBridge() {}

async function deployPoSOracle(account) {
    await deployContract("PoSOracle", account, 0);
}

async function deployCCFXBridge(account) {
    let addr = await deployContract("CCFXBridge", account, 0);
    await deployContract("Proxy1967", account, 0, addr, InitializerSig);
}

async function setupCCFXBridge(account) {
    let contract = await conflux.getContractAt(
        "CCFXBridge",
        process.env.CCFX_BRIDGE
    );

    const receipt2 = await contract
        .setPoSPool(process.env.POS_POOL_POW_ADDRESS)
        .sendTransaction({
            from: account.address,
        })
        .executed();
    logReceipt(receipt2, "setPosPool");

    const receipt3 = await contract
        .setPoSOracle(process.env.POS_ORACLE)
        .sendTransaction({
            from: account.address,
        })
        .executed();
    logReceipt(receipt3, "setPoSOracle");

    const receipt4 = await contract
        .setESpacePool(process.env.CCFX)
        .sendTransaction({
            from: account.address,
        })
        .executed();
    logReceipt(receipt4, "setESpacePool");
}

async function upgradeCCFXBridge(account) {
    let addr = await deployContract("CCFXBridge", account, 0);
    let contract = await conflux.getContractAt(
        "Proxy1967",
        process.env.CCFX_BRIDGE
    );

    let receipt = await contract
        .upgradeTo(addr)
        .sendTransaction({
            from: account.address,
        })
        .executed();

    logReceipt(receipt, "upgrade CCFXBridge");
}

async function deployContract(name, account, value, ...params) {
    console.log("Start to deploy", name);
    const Contract = await conflux.getContractFactory(name);

    const deployReceipt = await Contract.constructor(...params)
        .sendTransaction({
            from: account.address,
            value,
        })
        .executed();

    if (deployReceipt.outcomeStatus === 0) {
        console.log(`${name} deployed to:`, deployReceipt.contractCreated);
        return deployReceipt.contractCreated;
    } else {
        console.log(`${name} deploy failed`);
        return null;
    }
}
