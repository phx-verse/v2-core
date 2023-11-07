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
    const ratioBase = await swcfxBridge.eSpaceRatioBase();
    const posRatio = await swcfxBridge.eSpacePoSRatio();
    setInterval(() => handleTasks(ratioBase, posRatio), 1000 * 60 * 5);
}

main().catch(console.log);

async function handleTasks(ratioBase, posRatio) {
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

    // calculate need redeem amount
    const totalSupply = await swcfxBridge.eSpaceTotalSupply();
    const inPos = await swcfxBridge.eSpaceTotalInPoS();
    const needRedeem = 0;
    if (inPos > 0) {
        const should =
            ((totalSupply - BigInt(1000_000) * BigInt(1e18)) * posRatio) /
            ratioBase;
        needRedeem = inPos - should;
    }
    if (needRedeem > 0) {
        let tx = await swcfxBridge.handleRedeem(needRedeem).sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Handle redeem");
    }

    // state vote
    let balance = await conflux.cfx.getBalance(process.env.SWCFX_BRIDGE);
    if (balance > Drip.fromCFX(1000)) {
        let tx = await swcfxBridge.stakeVotes().sendTransaction({
            from: account.address,
        });
        await tx.executed();
        console.log("Stake votes");
    }
}
