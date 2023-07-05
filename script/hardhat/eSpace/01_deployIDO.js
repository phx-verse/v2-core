const { ethers } = require("hardhat");

main().catch(console.log);

async function main() {
    const Contract = await ethers.getContractFactory("IDO");
    const contract = await Contract.deploy(process.env.PHX);
    await contract.deployed();
    console.log("IDO impl deployed to:", contract.address);
}
