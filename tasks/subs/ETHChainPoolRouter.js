let {createFactory} = require("../../utils/create.js");

task("ETHChainPoolRouter: deploy", "router deploy")
    .addParam("id","pool id")
    .addParam("butter","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);

        let ETHChainPoolRouter = await ethers.getContractFactory("ETHChainPoolRouter");
        let param = ethers.AbiCoder.defaultAbiCoder().encode(["address","address","uint8"], [deployer.address, taskArgs.butter, taskArgs.id]);
        let proxy_salt = process.env.ROUTER_PROXY_SALT;
        let proxy = await createFactory(proxy_salt, ETHChainPoolRouter.bytecode, param);
        const verifyArgs = [deployer.address, taskArgs.butter, taskArgs.id].map((arg) => (typeof arg == "string" ? `'${arg}'` : arg)).join(" ");
        console.log(`To verify proxy, run: npx hardhat verify --network ${hre.network.name} --contract contracts/ETHChainPoolRouter.sol:ETHChainPoolRouter ${proxy[0]} ${verifyArgs}`);
    });

task("ETHChainPoolRouter:setButterRouter", "set ButterRouter address")
    .addParam("router","router address")
    .addParam("butter","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ETHChainPoolRouter", taskArgs.router, deployer);
        await (await router.setButterRouter(taskArgs.butter)).wait();
    });

task("ETHChainPoolRouter:setPoolId", "set pool Id ")
    .addParam("router","router address")
    .addParam("id","pool id")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ETHChainPoolRouter", taskArgs.router,deployer);
        await (await router.setPoolId(taskArgs.id)).wait();
    });

task("ETHChainPoolRouter:updateKeepers", "updateKeepers")
    .addParam("router","router address")
    .addParam("keeper","pool address")
    .addParam("flag","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ETHChainPoolRouter", taskArgs.router, deployer);
        await (await router.updateKeepers(taskArgs.keeper, taskArgs.flag)).wait();
    });

task("register:grantRole", "set token outFee")
    .addParam("router","router address")
    .addParam("role", "role address")
    .addParam("account", "account address")
    .addOptionalParam("grant", "grant or revoke", true, types.boolean)
    .setAction(async (taskArgs, hre) => {

    const { deploy } = hre.deployments;
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];
    console.log("deployer:", deployer.address);
    let router = await ethers.getContractAt("ETHChainPoolRouter", taskArgs.router, deployer);
  
    let role;
    if (taskArgs.role === "manage" || taskArgs.role === "manager") {
        role = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
    } else {
        role = ethers.ZeroHash;
    }

    if (taskArgs.grant) {
        await (await router.grantRole(role, taskArgs.account)).wait();
        console.log(`grant ${taskArgs.account} role ${role}`);
    } else {
        await router.revokeRole(role, taskArgs.account);
        console.log(`revoke ${taskArgs.account} role ${role}`);
    }
});