let {createFactory} = require("../../utils/create.js");

task("ChainPoolRouter: deploy", "router deploy")
    .addParam("id","pool id")
    .addParam("butter","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let impl = await deploy("ChainPoolRouter", {
            from: deployer.address,
            args: [],
            log: true,
            contract: "ChainPoolRouter",
        });
        let impl_addr = impl.address;
        let Router = await ethers.getContractFactory("ChainPoolRouter");
        let data = await Router.interface.encodeFunctionData("initialize", [deployer.address, taskArgs.butter, taskArgs.id]);
        let param = ethers.AbiCoder.defaultAbiCoder().encode(["address","bytes"], [impl_addr,data]);
        let proxy_salt = process.env.ROUTER_PROXY_SALT;
        let FeProxy = await ethers.getContractFactory("FeProxy");
        let proxy = await createFactory(proxy_salt,FeProxy.bytecode,param);
        const verifyArgs = [impl_addr,data].map((arg) => (typeof arg == "string" ? `'${arg}'` : arg)).join(" ");
        console.log(`To verify proxy, run: npx hardhat verify --network ${hre.network.name} --contract contracts/FeProxy.sol:FeProxy ${proxy[0]} ${verifyArgs}`);
        console.log(`To verify impl, run: npx hardhat verify --network ${hre.network.name} --contract contracts/ChainPoolRouter.sol:ChainPoolRouter ${impl_addr}`);
    });

task("ChainPoolRouter:upgradeTo", "upgradeTo")
    .addParam("router","router address")
    .addOptionalParam("impl","router address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ChainPoolRouter",taskArgs.router,deployer);
        let impl_addr;
        if(taskArgs.impl){
            impl_addr = taskArgs.impl;
        } else {
            let impl = await deploy("ChainPoolRouter", {
                from: deployer.address,
                args: [],
                log: true,
                contract: "ChainPoolRouter",
            });
            impl_addr = impl.address;
            console.log(`To verify impl, run: npx hardhat verify --network ${hre.network.name} --contract contracts/ChainPoolRouter.sol:ChainPoolRouter ${impl_addr}`);
        }
        await (await router.upgradeTo(impl_addr)).wait();
    });

task("ChainPoolRouter:setButterRouter", "set ButterRouter address")
    .addParam("router","router address")
    .addParam("butter","pool address")
    .setAction(async (taskArgs, hre) => {

        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ChainPoolRouter", taskArgs.router, deployer);
        await (await router.setButterRouter(taskArgs.butter)).wait();
    });

task("ChainPoolRouter:setPoolId", "set pool Id ")
    .addParam("router","router address")
    .addParam("id","pool id")
    .setAction(async (taskArgs, hre) => {

        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("ChainPoolRouter", taskArgs.router,deployer);
        await (await router.setPoolId(taskArgs.id)).wait();
    });


task("ChainPoolRouter:grantRole", "set token outFee")
    .addParam("router","router address")
    .addParam("role", "role address")
    .addParam("account", "account address")
    .addOptionalParam("grant", "grant or revoke", true, types.boolean)
    .setAction(async (taskArgs, hre) => {

    const accounts = await ethers.getSigners();
    const deployer = accounts[0];
    console.log("deployer:", deployer.address);
    let router = await ethers.getContractAt("ETHChainPoolRouter", taskArgs.router, deployer);
  
    let role;
    if (taskArgs.role === "manage" || taskArgs.role === "manager") {
        role = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
    } else if (taskArgs.role === "keeper"){
        role = ethers.keccak256(ethers.toUtf8Bytes("KEEPER_ROLE"));
    } else if(taskArgs.role === "upgrade" || taskArgs.role === "upgrader"){
        role = ethers.keccak256(ethers.toUtf8Bytes("UPGRADE_ROLE"));
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