const { conflux, account, logReceipt } = require("../script/hardhat/init.js");
const {
    abi,
    bytecode,
} = require("../artifacts/src/Core/CCFXBridge.sol/CCFXBridge.json"); // this is hardhat compile output
const { Drip } = require("js-conflux-sdk");

const ONE_VOTE_CFX = BigInt(Drip.fromCFX(1000));
const { CCFX_BRIDGE } = process.env;

const ccfxBridge = conflux.Contract({
    abi,
    address: CCFX_BRIDGE,
});

async function main() {
    /* let hash = await ccfxBridge.handleFirstRedeem().sendTransaction({
        from: account.address,
    });

    console.log("handleFirstRedeem tx hash: ", hash); */
    setInterval(async () => {
        await handleCrossSpaceTask();
    }, 1000 * 60 * 1);
}

main().catch(console.log);

async function handleCrossSpaceTask() {
    // step 1 Cross CFX from eSpace to Core
    const mappedBalance = await ccfxBridge.mappedBalance();
    if (mappedBalance > 0) {
        const receipt = await ccfxBridge
            .transferFromEspace()
            .sendTransaction({
                from: account.address,
            })
            .executed();
        logReceipt(receipt, "Cross CFX from eSpace to Core");
    }

    // step2 Claim interest
    const interest = await ccfxBridge.poolInterest();
    if (interest > 0) {
        const receipt = await ccfxBridge
            .claimInterest()
            .sendTransaction({
                from: account.address,
            })
            .executed();
        logReceipt(receipt, "Claim interest");
    }

    // step3 Handle redeem
    const redeemLen = await ccfxBridge.eSpaceRedeemLen();
    if (redeemLen > 0) {
        let summary = await ccfxBridge.poolSummary();

        if (summary.unlocked > 0) {
            await _handleRedeem(); // do withdraw
        }

        let balance = await conflux.cfx.getBalance(CCFX_BRIDGE);
        let unlocking = summary.votes - summary.available - summary.unlocked;
        let totalNeedRedeem = await ccfxBridge.eSpacePoolTotalRedeemed();
        if (
            summary.locked > 0 &&
            balance + unlocking * ONE_VOTE_CFX < totalNeedRedeem
        ) {
            await _handleRedeem(); // do unlock
        }
    }

    // step4 Stake votes
    const stakeAbleBalance = await ccfxBridge.stakeAbleBalance();
    const totalNeedRedeem = await ccfxBridge.eSpacePoolTotalRedeemed();
    if (stakeAbleBalance - totalNeedRedeem > ONE_VOTE_CFX) {
        const receipt = await ccfxBridge
            .stakeVotes()
            .sendTransaction({
                from: account.address,
            })
            .executed();
        logReceipt(receipt, "Stake votes");
    }
}

async function _handleRedeem() {
    const receipt = await ccfxBridge
        .handleRedeem()
        .sendTransaction({
            from: account.address,
        })
        .executed();
    logReceipt(receipt, "Handle redeem");
}
