import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'
import { TwoWayConfig, generateConnectionsConfig } from '@layerzerolabs/metadata-tools'
import { OAppEnforcedOption } from '@layerzerolabs/toolbox-hardhat'

import type { OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

/**
 *  WARNING: ONLY 1 OFTAdapter should exist for a given global mesh.
 *  The token address for the adapter should be defined in hardhat.config. This will be used in deployment.
 *
 *  for example:
 *
 *       'optimism-testnet': {
 *           eid: EndpointId.OPTSEP_V2_TESTNET,
 *           url: process.env.RPC_URL_OP_SEPOLIA || 'https://optimism-sepolia.gateway.tenderly.co',
 *           accounts,
 *         oftAdapter: {
 *             tokenAddress: '0x0', // Set the token address for the OFT adapter
 *         },
 *     },
 */
const ethereumContract: OmniPointHardhat = {
    eid: EndpointId.ETHEREUM_V2_MAINNET,
    contractName: 'OPENOFTAdapter',
}

// const baseContract: OmniPointHardhat = {
//     eid: EndpointId.BASE_V2_MAINNET,
//     contractName: 'OmnichainOpen',
// }

const bnbContract: OmniPointHardhat = {
    eid: EndpointId.BSC_V2_MAINNET,
    contractName: 'OmnichainOpen',
}

//OFT multisig contract address:0x7d6E779fe16fD2580a038A1094e8c855BA56e37D
const ownerAddr = "0x7d6E779fe16fD2580a038A1094e8c855BA56e37D"
const delegateAddr = "0x7d6E779fe16fD2580a038A1094e8c855BA56e37D"

const EVM_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
    {
        msgType: 1,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 80000,
        value: 0,
    },
]

// With the config generator, pathways declared are automatically bidirectional
// i.e. if you declare A,B there's no need to declare B,A
const pathways: TwoWayConfig[] = [
    // [
    //     ethereumContract, // Chain A contract
    //     baseContract, // Chain C contract
    //     [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
    //     [1, 1], // [A to B confirmations, B to A confirmations]
    //     [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // Chain C enforcedOptions, Chain A enforcedOptions
    // ],
    [
        ethereumContract, // Chain A contract
        bnbContract, // Chain C contract
        [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
        [1, 1], // [A to B confirmations, B to A confirmations]
        [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // Chain C enforcedOptions, Chain A enforcedOptions
    ],
    // [
    //     baseContract, // Chain A contract
    //     bnbContract, // Chain C contract
    //     [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
    //     [1, 1], // [A to B confirmations, B to A confirmations]
    //     [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // Chain C enforcedOptions, Chain A enforcedOptions
    // ],
]

export default async function () {
  // Generate the connections config based on the pathways
  const connections = await generateConnectionsConfig(pathways);

  return {
    contracts: [
      {
        contract: ethereumContract,
        config: {
          delegate: delegateAddr,
          owner: ownerAddr,
        },
      },
      // { contract: baseContract },
      {
        contract: bnbContract,
        config: {
          delegate: delegateAddr,
          owner: ownerAddr,
        },
      },
    ],
    connections,
  };
}


