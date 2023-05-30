module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    await deploy("PHX", {
        from: deployer,
        args: [process.env.TREASURY],
        log: true,
    });
};
module.exports.tags = ["PHX"];
module.exports.id = "phx";
