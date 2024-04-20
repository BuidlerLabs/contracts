require('dotenv').config()
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "hardhat-gas-reporter"
import "hardhat-abi-exporter"
import "hardhat-preprocessor"

export default {
  defaultNetwork: process.env.DEFAULT_NETWORK,
  gasReporter: {
    showTimeSpent: true,
    currency: 'USD',
  },
  networks: {
    test: {
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 60 * 30 * 1000,
      url: "http://127.0.0.1:8545",
      gas: 5000000,
    },
    arb_sepolia: {
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 60 * 30 * 1000,
      url: "https://arb-sepolia.g.alchemy.com/v2/81GwSFC4HeSp5_LV2mIxWBRHlGjY_pt6",
      gas: 5000000,
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        },
      },
    ],
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './build/artifacts',
  },
  abiExporter: {
    path: './build/abi',
    clear: true,
    flat: true,
    spacing: 2,
  },
  typechain: {
    outDir: './build/types',
    target: 'ethers-v5',
  },
}
