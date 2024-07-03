let {createFactory} = require("../../utils/create.js");

task("router:deploy", "router deploy")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let impl = await deploy("Router", {
            from: deployer.address,
            args: [],
            log: true,
            contract: "Router",
        });
        let impl_addr = impl.address;
        let Router = await ethers.getContractFactory("Router");
        let data = await Router.interface.encodeFunctionData("initialize", [deployer.address]);
        let param = ethers.AbiCoder.defaultAbiCoder().encode(["address","bytes"], [impl_addr,data]);
        let proxy_salt = process.env.ROUTER_PROXY_SALT;
        let FeProxy = await ethers.getContractFactory("FeProxy");
        let proxy = await createFactory(proxy_salt,FeProxy.bytecode,param);
        const verifyArgs = [impl_addr,data].map((arg) => (typeof arg == "string" ? `'${arg}'` : arg)).join(" ");
        console.log(`To verify proxy, run: npx hardhat verify --network ${hre.network.name} --contract contracts/FeProxy.sol:FeProxy ${proxy[0]} ${verifyArgs}`);
        console.log(`To verify impl, run: npx hardhat verify --network ${hre.network.name} --contract contracts/Router.sol:Router ${impl_addr}`);
    });

task("router:upgradeTo", "upgradeTo")
    .addParam("router","router address")
    .addOptionalParam("impl","router address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("Router",taskArgs.router,deployer);
        let impl_addr;
        if(taskArgs.impl){
            impl_addr = taskArgs.impl;
        } else {
            let impl = await deploy("Router", {
                from: deployer.address,
                args: [],
                log: true,
                contract: "Router",
            });
            impl_addr = impl.address;
            console.log(`To verify impl, run: npx hardhat verify --network ${hre.network.name} --contract contracts/Router.sol:Router ${impl_addr}`);
        }
        await (await router.upgradeTo(impl_addr)).wait();
    });

task("router:setPool", "setPool")
    .addParam("router","router address")
    .addParam("pool","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("Router",taskArgs.router,deployer);
        await (await router.setPool(taskArgs.pool)).wait();
    });


task("router:setButterRouter", "set ButterRouter address")
    .addParam("router","router address")
    .addParam("butter","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("Router",taskArgs.router,deployer);
        await (await router.setButterRouter(taskArgs.butter)).wait();
    });


task("router:updateKeepers", "updateKeepers")
    .addParam("router","router address")
    .addParam("keeper","pool address")
    .addParam("flag","pool address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let router = await ethers.getContractAt("Router",taskArgs.router,deployer);
        await (await router.updateKeepers(taskArgs.keeper,taskArgs.flag)).wait();
    });