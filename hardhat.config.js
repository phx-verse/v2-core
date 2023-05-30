require("@nomicfoundation/hardhat-foundry");
require("hardhat-conflux");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-abi-exporter");
require("hardhat-deploy");
require("@nomiclabs/hardhat-solhint");
require("dotenv").config();
const { loadPrivateKey } = require("./script/hardhat/init.js");
const PRIVATE_KEY = loadPrivateKey();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.18",
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        ropsten: {
            url: process.env.ROPSTEN_URL || "",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        },
        cfx: {
            url: "https://main.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 1029,
        },
        cfx_test: {
            url: "https://test.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 1,
        },
        ecfx: {
            url: "https://evm.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 1030,
        },
        ecfx_test: {
            url: "https://evmtestnet.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 71,
        },
        net8889: {
            url: "http://net8889eth.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 8889,
        },
        net8888: {
            url: "http://net8888cfx.confluxrpc.com",
            accounts: [PRIVATE_KEY],
            chainId: 8888,
        },
    },
    abiExporter: {
        path: "./data/abi",
        // runOnCompile: true,
        clear: true,
        flat: true,
        only: ["CCFX", "IPoSPool"],
        spacing: 2,
        pretty: true,
        // format: "minimal",
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
        },
    },
};
