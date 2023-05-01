require("@nomicfoundation/hardhat-toolbox");

const res = require('dotenv').config();

// You may also use Alchemy.
const INFURA_KEY = process.env.INFURA_KEY;
const INFURA_URL = process.env.INFURA_GOERLI;
const GOERLI_RPC_URL = `${INFURA_URL}${INFURA_KEY}`;

// console.log(GOERLI_RPC_URL);
// console.log('------------------------')

// Beware: NEVER put real Ether into testing accounts.
const HH_PRIVATE_KEY_1 = process.env.METAMASK_PRIVATE_KEY;
const HH_PRIVATE_KEY_2 = process.env.METAMASK_2_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",

  defaultNetwork: "unima1",

  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  },

  networks: {
    
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: [ HH_PRIVATE_KEY_1, HH_PRIVATE_KEY_2 ],
    },
    
    unima1: {
      url: process.env.NOT_UNIMA_URL_1,
      accounts: [ HH_PRIVATE_KEY_1, HH_PRIVATE_KEY_2 ],
    },
    
    unima2: {
      url: process.env.NOT_UNIMA_URL_2,
      accounts: [ HH_PRIVATE_KEY_1, HH_PRIVATE_KEY_2 ],
    }

  }
};
