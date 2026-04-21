import 'dotenv/config'
import{vars} from 'hardhat/config'
import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import 'solidity-coverage'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

import './type-extensions'
import './tasks/sendOFT'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
let MNEMONIC;
// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
let PRIVATE_KEY;
const keyName = (process.env.VARNAME || "").toString();

if (vars.has(keyName)){
     PRIVATE_KEY = vars.get(keyName);
     console.log(`\x1b[32mNote: ${keyName} key is configured\x1b[0m`);
}
else{
     MNEMONIC = process.env.MNEMONIC
     PRIVATE_KEY = process.env.PRIVATE_KEY
}

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.27',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
      //-----mainnets------
      'Ethereum': {
            eid: EndpointId.ETHEREUM_V2_MAINNET,
            url: process.env.RPC_URL_ETHEREUM,
            accounts,
            oftAdapter: {
                tokenAddress: '0xA227Cc36938f0c9E09CE0e64dfab226cad739447', // Set the token address for the OFT adapter (OPEN Token mainnet)
            },
        },
        // 'Base': {
        //     eid: EndpointId.BASE_V2_MAINNET,
        //     url: process.env.RPC_URL_BASE,
        //     accounts,
        // },
        'BSC': {
            eid: EndpointId.BSC_V2_MAINNET,
            url: process.env.RPC_URL_BNB,
            accounts,
        },
        // //-----testnets------
        // 'sepolia-testnet': {
        //     eid: EndpointId.SEPOLIA_V2_TESTNET,
        //     url: process.env.RPC_URL_SEPLOIA_TESTNET,
        //     accounts,
        //     oftAdapter: {
        //         tokenAddress: '', // Set the token address for the OFT adapter
        //     },
        // },
        // 'base-testnet': {
        //     eid: EndpointId.BASESEP_V2_TESTNET,
        //     url: process.env.RPC_URL_BASE_TESTNET,
        //     accounts,
        // },
        // 'bnb-testnet': {
        //     eid: EndpointId.BSC_V2_TESTNET,
        //     url: process.env.RPC_URL_BNB_TESTNET,
        //     accounts,
        // },
        // //new network
        // 'amoy-testnet': {
        //     eid: EndpointId.AMOY_V2_TESTNET,
        //     url: process.env.RPC_URL_AMOY_TESTNET,
        //     accounts,
        // },
        hardhat: {
            // Need this for testing because TestHelperOz5.sol is exceeding the compiled contract size limit
            allowUnlimitedContractSize: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
}

export default config
