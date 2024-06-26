import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
import 'hardhat-deploy';
import "hardhat-tracer";
import "hardhat-abi-exporter";
import "./tasks";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
		compilers: [
			{ version: "0.8.19", settings: { optimizer: { enabled: true, runs: 200 } } },
		],
	},

  networks:{
    hardhat: {
      chainId:1,
      initialBaseFeePerGas: 0,
    },
    Eth: {
      url: `https://mainnet.infura.io/v3/` + process.env.INFURA_KEY,
      chainId : 1,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    Map : {
      chainId: 22776,
      url:"https://rpc.maplabs.io",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    Makalu: {
      chainId: 212,
      url:"https://testnet-rpc.maplabs.io",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },

  abiExporter: {
    path: './abi',
    runOnCompile:true,
    clear: true,
    flat: true
  },
  
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      bttc:"49V6QCE7UIBPPINR3XA8WUHP17MB14FTBX"
    },
    customChains: [
      {
        network: "bttc",
        chainId: 199,
        urls: {
          apiURL: "https://api.bttcscan.com/api",
          browserURL: "https://bttcscan.com/"
        },
      },
    ]
  }
};




export default config;
