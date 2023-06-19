const hre = require("hardhat");
const { deployContract, InitializerSig } = require("../init");

main().catch(console.log);

async function main() {
    await deployCCFXBridge();
}

async function deployCCFXBridge() {
    let addr = await deployContract(hre, "CCFXBridge");
    await deployContract(hre, "Proxy1967", 0, addr, InitializerSig);
}
