const hre = require("hardhat");
const { deployContract, logReceipt } = require("../init");

main().catch(console.log);

async function main() {
    await upgradeCCFXBridge();
}

async function upgradeCCFXBridge() {
    const [account] = await hre.conflux.getSigners();

    let addr = await deployContract(hre, "CCFXBridge");
    if (!addr) return;

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
