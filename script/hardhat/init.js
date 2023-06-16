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

async function deployContract(hre, name, value = 0, ...params) {
    console.log("Start to deploy", name);
    const [account] = await hre.conflux.getSigners();
    const Contract = await hre.conflux.getContractFactory(name);

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

const account = conflux.wallet.addPrivateKey(loadPrivateKey());

const InitializerSig = "0x8129fc1c";

module.exports = {
    conflux,
    account,
    logReceipt,
    loadPrivateKey,
    deployContract,
    InitializerSig,
};
