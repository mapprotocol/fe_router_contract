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
        impl_addr = impl.address;
        let Router = await ethers.getContractFactory("Router");
        let data = await Router.interface.encodeFunctionData("initialize", [deployer.address]);
        let proxy_salt = process.env.ROUTER_PROXY_SALT;
        let proxy = await createFactory(hre, deployer, "FeProxy", ["address", "bytes"], [implAddr, data], proxy_salt);
        const verifyArgs = [impl_addr,data].map((arg) => (typeof arg == "string" ? `'${arg}'` : arg)).join(" ");
        console.log(`To verify proxy, run: npx hardhat verify --network Network --contract contracts/FeProxy.sol:FeProxy ${proxy.address} ${verifyArgs}`);
        console.log(`To verify impl, run: npx hardhat verify --network Network --contract contracts/Router.sol:Router ${impl_addr}`);
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
            let impl = await deploy("Pool", {
                from: deployer.address,
                args: [],
                log: true,
                contract: "Pool",
            });
            impl_addr = impl.address;
            console.log(`To verify impl, run: npx hardhat verify --network Network --contract contracts/Router.sol:Router ${impl_addr}`);
        }
        await (await router.upgradeTo(impl_addr)).wait();
    });