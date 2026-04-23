import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'
import { TwoWayConfig, generateConnectionsConfig } from '@layerzerolabs/metadata-tools'
import { OAppEnforcedOption } from '@layerzerolabs/toolbox-hardhat'

import type { OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

/**
 *  WARNING: ONLY 1 OFTAdapter should exist for a given global mesh.
 *  The token address for the adapter is defined in hardhat.config and
 *  consumed at deployment time.
 */

// ── Owner / delegate (testnet multisig) ──────────────────────────────────────
//OFT multisig contract address:0x7d6E779fe16fD2580a038A1094e8c855BA56e37D
const ownerAddr    = '0x7d6E779fe16fD2580a038A1094e8c855BA56e37D'
const delegateAddr = '0x7d6E779fe16fD2580a038A1094e8c855BA56e37D'


// ── Block confirmations per source chain ─────────────────────────────────────
const ETH_CONFIRMATIONS  = 15
const BNB_CONFIRMATIONS = 20

// ── OApps (per chain) ────────────────────────────────────────────────────────
// Chain A — Ethereum Mainnet
const ethereumContract: OmniPointHardhat = {
    eid: EndpointId.ETHEREUM_V2_MAINNET,
    contractName: 'OPENOFTAdapter',
}

// Chain B — BSC Mainnet
const bnbContract: OmniPointHardhat = {
    eid: EndpointId.BSC_V2_MAINNET,
    contractName: 'OmnichainOpen',
}


// ── Enforced options, keyed by DESTINATION chain ─────────────────────────────
// ~20k above the GAS_PROFILING
const ENFORCED_OPTS_TO_BNB: OAppEnforcedOption[] = [
    { msgType: 1, optionType: ExecutorOptionType.LZ_RECEIVE, gas: 90_000, value: 0 },
]

const ENFORCED_OPTS_TO_ETH: OAppEnforcedOption[] = [
    { msgType: 1, optionType: ExecutorOptionType.LZ_RECEIVE, gas: 90_000, value: 0 },
]

// ── Pathways ─────────────────────────────────────────────────────────────────
// Declared once; the generator materializes both directions.
// Enforced-options tuple order: [ opts applied when B receives, opts applied when A receives ].
//
//   Ethereum → BNB  lands on OmnichainOpen    → ENFORCED_OPTS_TO_BNB
//   BNB → Ethereum  lands on OPENOFTAdapter   → ENFORCED_OPTS_TO_ETH
const pathways: TwoWayConfig[] = [
    [
        ethereumContract, // Chain A
        bnbContract,    // Chain B
        [['Google', 'LayerZero Labs', 'Canary', 'Deutsche Telekom'], []], // [ requiredDVNs, [ optionalDVNs, threshold ] ]
        [ETH_CONFIRMATIONS, BNB_CONFIRMATIONS],
        [ENFORCED_OPTS_TO_BNB, ENFORCED_OPTS_TO_ETH],
    ],
]

export default async function () {
    const connections = await generateConnectionsConfig(pathways)

    return {
        contracts: [
            { contract: ethereumContract, config: { delegate: delegateAddr, owner: ownerAddr } },
            { contract: bnbContract,    config: { delegate: delegateAddr, owner: ownerAddr } },
        ],
        connections,
    }
}
