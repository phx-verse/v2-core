const { Drip } = require("js-conflux-sdk");
const { conflux, account } = require("../script/hardhat/init.js");
const {
    abi,
} = require("../artifacts/src/Core/SWCFXBridge.sol/SWCFXBridge.json"); // this is hardhat compile output

const swcfxBridge = conflux.Contract({
    abi,
    address: process.env.SWCFX_BRIDGE,
});

async function main() {
    setInterval(handleTasks, 1000 * 60 * 5);
}

main().catch(console.log);

async function handleTasks() {
    let interest = await swcfxBridge.poolInterest();
    if (interest > 0) {
        let tx = await swcfxBridge.claimInterest().sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Withdraw interest");
    }

    let mappedBalance = await swcfxBridge.mappedBalance();
    if (mappedBalance > 0) {
        let tx = await swcfxBridge.transferFromESpace().sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Cross from eSpace");
    }

    let redeemed = await swcfxBridge.eSpaceTotalRedeemed();
    if (redeemed > 0) {
        let tx = await swcfxBridge.handleRedeem().sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Handle redeem");
    }

    let balance = await conflux.cfx.getBalance(process.env.SWCFX_BRIDGE);
    if (balance > Drip.fromCFX(1000)) {
        let tx = await swcfxBridge.stakeVotes().sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Stake votes");
    }
}
