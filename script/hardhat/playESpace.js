const { ethers } = require("hardhat");

async function main() {
    const PHXRate = await ethers.getContractFactory("PHXRate");
    const txData = PHXRate.interface.encodeFunctionData("initialize", [
        [
            {
                startTime: 86401,
                rate: 1000,
            },
            {
                startTime: 31536001,
                rate: 0,
            },
        ],
    ]);
    console.log(txData);
}

main().catch(console.log);

async function playLiquidityPool() {
    const [account] = await ethers.getSigners();
    const liquidityPool = await ethers.getContractAt(
        "LiquidityPool",
        process.env.LIQUIDITY_POOL
    );

    /* let tx = await liquidityPool.deposit({
        value: ethers.utils.parseEther("10000"),
    });
    await tx.wait();
    let balance = await liquidityPool.balances(account.address);
    console.log("balance", balance.toString()); */

    /* let tx = await liquidityPool.withdraw(ethers.utils.parseEther("10"));
    await tx.wait();
    let balance = await liquidityPool.balances(account.address);
    console.log("balance", balance.toString()); */
}
