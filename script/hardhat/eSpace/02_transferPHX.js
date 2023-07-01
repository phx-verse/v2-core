const { ethers } = require("hardhat");

main().catch(console.log);

async function main() {
    const contract = await ethers.getContractAt(
        "PHXTreasury",
        process.env.TREASURY
    );
    const tx = await contract.transfer(
        process.env.TARGET,
        ethers.utils.parseEther("24000000")
    );
    await tx.wait();
    console.log("PHX transferred from treasury");
}
