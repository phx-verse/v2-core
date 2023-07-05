const { ethers } = require("hardhat");

main().catch(console.log);

async function main() {
    const contract = await ethers.getContractAt(
        "FarmingController",
        process.env.FARMING_CONTROLLER
    );
    let tx = await contract.add(
        1500,
        process.env.LP2,
        parseInt(Date.now() / 1000),
        true
    );
    await tx.wait();

    tx = await contract.setPoolName(1, "cCFX/CFX");
    await tx.wait();
    console.log("Add LP success");
}
