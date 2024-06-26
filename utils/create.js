let fs = require("fs");
let path = require("path");


let DEPLOY_FACTORY = "0x6258e4d2950757A749a4d4683A7342261ce12471";
let IDeployFactory_abi = [
    "function deploy(bytes32 salt, bytes memory creationCode, uint256 value) external",
    "function getAddress(bytes32 salt) external view returns (address)",
];

async function createFactory(salt, bytecode, param) {
    let [wallet] = await ethers.getSigners();
    let factory = await ethers.getContractAt(IDeployFactory_abi, DEPLOY_FACTORY, wallet);
    let salt_hash = await ethers.keccak256(await ethers.toUtf8Bytes(salt));
    // console.log("deploy factory address:", factory.address);
    console.log("deploy salt:", salt);
    let addr = await factory.getAddress(salt_hash);
    console.log("deployed to :", addr);
    let code = await ethers.provider.getCode(addr);
    let redeploy = false;
    if (code === "0x") {
        let create_code = ethers.solidityPack(["bytes", "bytes"], [bytecode, param]);
        let create = await (await factory.deploy(salt_hash, create_code, 0)).wait();
        if (create.status == 1) {
            redeploy = true;
        } else {
            console.log("deploy fail");
            throw "deploy fail";
        }
    } else {
        throw "already deploy, please change the salt if if want to deploy another contract ...";
    }

    return [addr, redeploy];
}




module.exports = {
    createFactory,
};