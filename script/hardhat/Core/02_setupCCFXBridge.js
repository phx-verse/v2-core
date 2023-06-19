const hre = require("hardhat");
const { logReceipt } = require("../init");

main().catch(console.log);

async function main() {
    await setupCCFXBridge();
}

async function setupCCFXBridge() {
    const [account] = await hre.conflux.getSigners();
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
