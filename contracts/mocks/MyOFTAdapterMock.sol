// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OPENOFTAdapter } from "../OPENOFTAdapter.sol";

// @dev WARNING: This is for testing purposes only
contract MyOFTAdapterMock is OPENOFTAdapter {
    constructor(address _token, address _lzEndpoint, address _delegate) OPENOFTAdapter(_token, _lzEndpoint, _delegate) {}
}
