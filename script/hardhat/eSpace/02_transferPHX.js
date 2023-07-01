const { ethers } = require("hardhat");

main().catch(console.log);

async function main() {
    const contract = await ethers.getContractAt(
        "PHXTreasury",
        process.env.FUND_TREASURY
    );
    const tx = await contract.transfer(
        process.env.TARGET,
        ethers.utils.parseEther("1000000")
    );
    await tx.wait();
    console.log("PHX transferred from treasury");
}
