require("@nomicfoundation/hardhat-foundry");
require("hardhat-conflux");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-abi-exporter");
require("hardhat-deploy");
require("@nomiclabs/hardhat-solhint");
require("dotenv").config();
const { loadPrivateKey } = require("./script/hardhat/init.js");
const PRIVATE_KEY = loadPrivateKey();

task("upgrade1967", "Upgrade a ERC1967 contracts")
    .addParam("contract", "Contract name used to upgrade")
    .addParam("address", "Contract address to upgrade")
    .setAction(async (args, hre) => {
        console.log(`Upgrading ${args.contract} at ${args.address}`);
        const Contract = await hre.ethers.getContractFactory(args.contract);
        const contract = await Contract.deploy();
        await contract.deployed();
        console.log(`${args.contract} impl deployed to:`, contract.address);

        const proxy1967 = await hre.ethers.getContractAt(
            "Proxy1967",
            args.address
        );
        const tx = await proxy1967.upgradeTo(contract.address);
        await tx.wait();

        console.log("Finished");
    });

task("setLPName", "Set LP name in FarmingController")
    .addParam("name", "LP name")
    .addParam("index", "LP index")
    .setAction(async function (args, hre) {
        const controller = await hre.ethers.getContractAt(
            "FarmingController",
            process.env.FARMING_CONTROLLER
        );
        const tx = await controller.setPoolName(
            parseInt(args.index),
            args.name
        );
        await tx.wait();
        console.log(`Set LP name "${args.name}" at index ${args.index}`);
    });

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
        only: [
            "CCFX",
            "IPoSPool",
            "PHX",
            "FarmingPool",
            "FarmingController",
            "VotingEscrow",
            "ERC20Metadata",
        ],
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
