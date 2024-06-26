let {createFactory} = require("../../utils/create.js");


task("pool:deploy", "pool deploy")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let impl = await deploy("Pool", {
            from: deployer.address,
            args: [],
            log: true,
            contract: "Pool",
        });
        impl_addr = impl.address;
        let Pool = await ethers.getContractFactory("Pool");
        let data = await Pool.interface.encodeFunctionData("initialize", [deployer.address]);
        let proxy_salt = process.env.POOL_PROXY_SALT;
        let proxy = await createFactory(hre, deployer, "FeProxy", ["address", "bytes"], [implAddr, data], proxy_salt);
        const verifyArgs = [impl_addr,data].map((arg) => (typeof arg == "string" ? `'${arg}'` : arg)).join(" ");
        console.log(`To verify proxy, run: npx hardhat verify --network Network --contract contracts/FeProxy.sol:FeProxy ${proxy.address} ${verifyArgs}`);
        console.log(`To verify impl, run: npx hardhat verify --network Network --contract contracts/Pool.sol:Pool ${impl_addr}`);
    });

task("pool:upgradeTo", "set router address")
    .addParam("pool","pool address")
    .addOptionalParam("impl","router address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let pool = await ethers.getContractAt("Pool",taskArgs.pool,deployer);
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
            console.log(`To verify impl, run: npx hardhat verify --network Network --contract contracts/Pool.sol:Pool ${impl_addr}`);
        }
        await (await pool.upgradeTo(impl_addr)).wait();
    });

task("pool:setRouter", "set router address")
    .addParam("pool","pool address")
    .addParam("router","router address")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let pool = await ethers.getContractAt("Pool",taskArgs.pool,deployer);
        await (await pool.setRouter(taskArgs.router)).wait();
    });

task("pool:updateSupportToken", "update support token")
    .addParam("pool","pool address")
    .addParam("token","router address")
    .addParam("flag","support or not")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let pool = await ethers.getContractAt("Pool",taskArgs.pool,deployer);
        let tokenList = taskArgs.token.split(",");
        await (await pool.updateSupportToken(tokenList,taskArgs.flag)).wait();
    });

task("pool:withdraw", "withdraw token")
    .addParam("pool","pool address")
    .addParam("receiver","receiver address")
    .addParam("amount","amount in wei")
    .setAction(async (taskArgs, hre) => {
        const { deploy } = hre.deployments;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        console.log("deployer:", deployer.address);
        let pool = await ethers.getContractAt("Pool",taskArgs.pool,deployer);
        await (await pool.withdraw(taskArgs.receiver,taskArgs.amount)).wait();
    });