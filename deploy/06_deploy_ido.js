module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy("IDO", {
        from: deployer,
        args: [process.env.PHX],
        log: true,
    });
};
module.exports.tags = ["ido"];
module.exports.id = "ido";
