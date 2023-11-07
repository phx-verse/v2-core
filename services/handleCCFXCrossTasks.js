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
    setInterval(async () => {
        try {
            await handleCrossSpaceTask();
        } catch (e) {
            console.error("handleCrossSpaceTask error: ", e);
        }
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
            // update summary
            summary = await ccfxBridge.poolSummary();
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

        if (balance >= totalNeedRedeem) {
            await _handleRedeem(); // handle redeem
        }
    } else {
        let summary = await ccfxBridge.poolSummary();
        if (summary.unlocked > 0) {
            await _handleRedeem(); // do withdraw
            // update summary
            summary = await ccfxBridge.poolSummary();
        }
        // do unstake when no redeem task to refund liquid pool
        let balance = await conflux.cfx.getBalance(CCFX_BRIDGE);
        let accInterest = await ccfxBridge.poolAccInterest();
        if (accInterest > balance) {
            let unlocking =
                summary.votes - summary.available - summary.unlocked;
            if (accInterest > balance + unlocking * ONE_VOTE_CFX) {
                let toUnlock = accInterest - balance - unlocking * ONE_VOTE_CFX;
                let toUnlockVote = toUnlock / ONE_VOTE_CFX;
                if (toUnlock > toUnlockVote * ONE_VOTE_CFX) toUnlockVote += 1n;
                if (toUnlockVote > 0) {
                    const receipt = await ccfxBridge
                        .unstakeVotes(toUnlockVote)
                        .sendTransaction({
                            from: account.address,
                        })
                        .executed();
                    logReceipt(receipt, "Unstake votes");
                }
            }
        }
    }

    // step4 Stake votes
    const stakeAbleBalance = await ccfxBridge.stakeAbleBalance();
    if (stakeAbleBalance > ONE_VOTE_CFX) {
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
    try {
        const receipt = await ccfxBridge
            .handleRedeem()
            .sendTransaction({
                from: account.address,
            })
            .executed();
        logReceipt(receipt, "Handle redeem");
    } catch (error) {
        console.error("Handle redeem error: ", error);
    }
}
