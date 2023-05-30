require("dotenv").config();
const { Conflux, sign, format } = require("js-conflux-sdk");

const conflux = new Conflux({
    url: process.env.RPC_URL,
    networkId: parseInt(process.env.NETWORK_ID),
});

function logReceipt(receipt, msg) {
    console.log(
        `${msg}: ${receipt.outcomeStatus === 0 ? "Success" : "Fail"} hash-${
            receipt.transactionHash
        }`
    );
}

function loadPrivateKey() {
    if (process.env.PRIVATE_KEY) {
        return process.env.PRIVATE_KEY;
    } else {
        const keystore = require(process.env.KEYSTORE);
        const privateKeyBuf = sign.decrypt(keystore, process.env.KEYSTORE_PWD);
        return format.hex(privateKeyBuf);
    }
}

const account = conflux.wallet.addPrivateKey(loadPrivateKey());

module.exports = {
    conflux,
    account,
    logReceipt,
    loadPrivateKey,
};
