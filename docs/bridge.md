# LayerZero OFT Adapter Deployment & Cross-Chain Bridge Guide

## High-Level Overview

This project demonstrates how to convert an existing ERC20 token (without LayerZero imports) into an Omnichain Fungible Token (OFT) using the LayerZero protocol. The approach uses the OFT Adapter pattern, which locks tokens on the source chain and enables cross-chain transfers to destination chains via LayerZero messaging.

**Summary of Steps:**
- Use your own ERC20 token as the source asset (no LayerZero code in the token).
- Deploy an OFT Adapter contract on the source chain to lock/unlock tokens.
- Deploy OFT contracts on destination chains.
- Configure LayerZero messaging to enable cross-chain transfers.

## Step-by-Step Deployment & Usage

### 1. Scaffold the Project

```sh
npx create-lz-oapp@latest
```

### 2. Prepare the Deployer

- Set up your deployer address (e.g., `0xDeployer...`).
- Fund the deployer with testnet tokens on all target chains.

### 3. Deploy the Source Token

- Deploy your ERC20 token on the source chain (e.g., Sepolia).
- Example token address: `0xTokenSource...`

### 4. Configure Hardhat and LayerZero

- Update `hardhat.config.ts` and `layerzero.config.ts` with your network and contract details.
- In `hardhat.config.ts`, set the `oftAdapter.tokenAddress` to your ERC20 token address.

### 5. Deploy Contracts
- use existing token / or deploy a mockERC20
- then set the token address in hardhat config.

#### a. Deploy OFT Adapter on Source Chain

```sh
npx hardhat lz:deploy --tags MyOFTAdapter --networks sepolia-testnet
```
- Example deployed address: `0xAdapterSource...`

#### b. Deploy OFT on Destination Chains

```sh
npx hardhat lz:deploy --tags MyOFT --networks base-testnet
npx hardhat lz:deploy --tags MyOFT --networks bnb-testnet
```
- Example deployed addresses: `0xOFTBase...`, `0xOFTBnb...`

### 6. Enable LayerZero Messaging

Wire the contracts for cross-chain communication:

```sh
npx hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

### 7. Sending Cross-Chain Transfers

Use the LayerZero helper tasks to send tokens across chains:

```sh
npx hardhat lz:oft:send --src-eid <srcEid> --dst-eid <dstEid> --amount <amount> --to <recipient>
```

- Example: Send from Sepolia to Base
  ```sh
  npx hardhat lz:oft:send --src-eid 40161 --dst-eid 40245 --amount 1 --to 0xRecipient...
  ```

- Example: Send from Sepolia to BNB
  ```sh
  npx hardhat lz:oft:send --src-eid 40161 --dst-eid 40102 --amount 1 --to 0xRecipient...
  ```

- Example: Send from Base to BNB
  ```sh
  npx hardhat lz:oft:send --src-eid 40245 --dst-eid 40102 --amount 0.1 --to 0xRecipient...
  ```

### 8. Scripts Usage (npm run)

You can use the following scripts with `npm run` from your project root:

- **Clean build artifacts:**
  ```sh
  npm run clean
  ```
  Removes `artifacts`, `cache`, and `out` directories.

- **Compile contracts (both Forge and Hardhat in parallel):**
  ```sh
  npm run compile
  ```
  Or individually:
  ```sh
  npm run compile:forge
  npm run compile:hardhat
  ```

- **Run all tests (Forge first, then Hardhat):**
  ```sh
  npm run test
  ```
  Or individually:
  ```sh
  npm run test:forge
  npm run test:hardhat
  ```

---

### Note on Ownership and Cross-Chain Peers

The OFT Adapter and OFT contracts are controlled by their respective owners. Setting up cross-chain communication (adding peers) is a crucial step when integrating a new chain. In the future, ownership and control of these contracts may be transferred to a governance contract or multisig for enhanced security and decentralization.

---

## What Was Done

- **No changes to the original contract source code.**
- **Adapter contract deployed on the source chain** to lock/unlock tokens.
- **OFT contracts deployed on destination chains** for cross-chain representation.
- **LayerZero configuration and wiring** enabled cross-chain messaging.
- **Cross-chain transfers tested** using LayerZero helper tasks in testnets.

---

## References

- See the main [README.md](../README.md) for a high-level description and further details about the OFT Adapter pattern and LayerZero protocol.
