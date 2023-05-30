const { conflux } = require("./init");
const { ethers } = require("ethers");
const ccfxInfo = require("../../artifacts/src/eSpace/CCFX.sol/CCFX.json");
const poolV1Info = require("../../artifacts/src/interfaces/IPoSPool.sol/IPoSPool.json");
const {
    abi,
} = require("../../artifacts/src/Core/CCFXBridge.sol/CCFXBridge.json");
const ONE_VOTE = BigInt(1e18 * 1000);

const {
    CCFX_BRIDGE,
    POS_POOL_POW_ADDRESS,
    CCFX,
    ESPACE_TESTNET_URL,
} = process.env;

const ccfxBridge = conflux.Contract({
    abi,
    address: CCFX_BRIDGE,
});

const posPool = conflux.Contract({
    abi: poolV1Info.abi,
    address: POS_POOL_POW_ADDRESS,
});

const provider = new ethers.providers.JsonRpcProvider(ESPACE_TESTNET_URL);
const ccfx = new ethers.Contract(CCFX, ccfxInfo.abi, provider);

async function main() {
    await calculate();
}

main().catch(console.log);

async function estimatedUnlockTimeForCore() {
    const { blockNumber } = await conflux.cfx.getStatus();

    const availableTime = [];
    const userSummary = await ccfxBridge.poolSummary();
    let balance = await conflux.cfx.getBalance(CCFX_BRIDGE);

    if (balance > 0 || userSummary.unlocked > 0) {
        availableTime.push({
            amount: balance + userSummary.unlocked * ONE_VOTE, // TODO: add bridge mappedBalance
            time: new Date(),
        });
    }

    // unlocking
    const userOutQueue = await posPool.userOutQueue(CCFX_BRIDGE);
    for (let node of userOutQueue) {
        if (node.endBlock <= blockNumber) continue;
        availableTime.push({
            amount: node.votePower * ONE_VOTE,
            time: new Date(
                Date.now() +
                    ((parseInt(node.endBlock.toString()) - blockNumber) / 2) *
                        1000
            ),
        });
    }

    // locked available in 24 hours
    if (userSummary.locked > 0) {
        availableTime.push({
            amount: userSummary.locked * ONE_VOTE,
            time: new Date(Date.now() + 24 * 60 * 60 * 1000),
        });
    }

    // locking
    const userInQueue = await posPool.userInQueue(CCFX_BRIDGE);
    for (let node of userInQueue) {
        if (node.endBlock <= blockNumber) continue;
        availableTime.push({
            amount: node.votePower * ONE_VOTE,
            time: new Date(
                Date.now() +
                    ((parseInt(node.endBlock.toString()) - blockNumber) / 2) *
                        1000 +
                    24 * 60 * 60 * 1000
            ),
        });
    }

    return availableTime;
}

async function calculate(address) {
    let userRedeemed = await ccfx.userRedeemedAssets(address);
    if (userRedeemed.eq(0)) {
        return [];
    }
    const redeemQueue = await ccfx.redeemQueue();
    // console.log(redeemQueue);
    let availableQueue = await estimatedUnlockTimeForCore();
    // console.log(estimateTime);
    let preTotal = BigInt(0);
    for (let i = 0; i < redeemQueue.length; i++) {
        const redeem = redeemQueue[i];
        const amount = redeem.amount.toBigInt();
        const availableTotal = BigInt(0);
        for (let j = 0; j < availableQueue.length; j++) {
            availableTotal += availableQueue[j].amount;
            if (availableTotal - preTotal >= amount) {
                redeem.unlockTime = availableQueue[j].time;
            }
        }
        preTotal += redeem.amount.toBigInt();
    }

    return redeemQueue.filter((item) => item.user === address);
}
