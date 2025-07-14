// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// @dev WARNING: This is for testing purposes only
contract Open is ERC20, ERC20Burnable {

    string internal constant NAME = "Open";
    string internal constant SYMBOL = "OPEN";
    constructor(address recipient) ERC20(NAME, SYMBOL) {
        _mint(recipient, 1_000_000_000 * 10 ** decimals());
    }
}