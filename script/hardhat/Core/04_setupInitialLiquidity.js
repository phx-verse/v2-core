const hre = require("hardhat");
const { logReceipt } = require("../init");
const { Drip } = require("js-conflux-sdk");

main().catch(console.log);

async function main() {
    const [account] = await hre.conflux.getSigners();

    let contract = await conflux.getContractAt(
        "CCFXBridge",
        process.env.CCFX_BRIDGE
    );

    let receipt = await contract
        .depositPoolInterest()
        .sendTransaction({
            from: account.address,
            value: Drip.fromCFX(50000),
        })
        .executed();

    logReceipt(receipt, "setup initial liquidity");
}
