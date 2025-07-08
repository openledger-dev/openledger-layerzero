// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";


/**
 * @title OmnichainOpen
 * @notice This contract implements an omnichain fungible token (OFT) using LayerZero’s OFT standard.
 *         It supports cross-chain token transfers and includes basic ownership control.
 *         The token is initialized with a name, symbol, LayerZero endpoint, and delegate owner.
 * @dev Extends LayerZero’s OFT contract for omnichain interoperability and OpenZeppelin's Ownable for access control.
 * @custom:security-contact security@openledger.xyz
 */
contract OmnichainOpen is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}
}
