// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";
import { Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { ILayerZeroReceiver } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";
import { IOAppComposer } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol";

/**
 * @title GasProfilerScript
 * @notice Profiles lzReceive and lzCompose gas usage across N runs.
 *
 * Usage (via package.json scripts):
 *
 *   pnpm gas:lzReceive \
 *     <rpcUrl> \
 *     <endpointAddress> \
 *     <srcEid> \
 *     <sender> \
 *     <dstEid> \
 *     <receiver> \
 *     <message> \
 *     <msgValue> \
 *     <numOfRuns>
 *
 *   pnpm gas:lzCompose \
 *     <rpcUrl> \
 *     <endpointAddress> \
 *     <srcEid> \
 *     <sender> \
 *     <dstEid> \
 *     <receiver> \
 *     <composer> \
 *     <composeMsg> \
 *     <msgValue> \
 *     <numOfRuns>
 */
contract GasProfilerScript is Script {

    // Allow this script to receive ETH (e.g. NativeOFTAdapter refunds).
    receive() external payable {}

    struct LzReceiveArgs {
        address endpointAddress;
        uint32  srcEid;
        address sender;
        uint32  dstEid;
        address receiver;
        bytes   message;
        uint256 msgValue;
        uint256 numOfRuns;
    }

    struct LzComposeArgs {
        address endpointAddress;
        uint32  srcEid;
        address sender;
        uint32  dstEid;
        address receiver;
        address composer;
        bytes   composeMsg;
        uint256 msgValue;
        uint256 numOfRuns;
    }

    struct LzReceiveColdArgs {
        address endpointAddress;
        uint32  srcEid;
        address sender;
        uint32  dstEid;
        address receiver;
        uint64  amountSD;
        uint256 msgValue;
        uint256 numOfRuns;
    }

    // ── lzReceive profiler ─────────────────────────────────────────────────────

    function run_lzReceive(
        string  calldata rpcUrl,
        address          endpointAddress,
        uint32           srcEid,
        address          sender,
        uint32           dstEid,
        address          receiver,
        bytes   calldata message,
        uint256          msgValue,
        uint256          numOfRuns
    ) external {
        vm.createSelectFork(rpcUrl);
        _loopLzReceive(LzReceiveArgs({
            endpointAddress: endpointAddress,
            srcEid:          srcEid,
            sender:          sender,
            dstEid:          dstEid,
            receiver:        receiver,
            message:         message,
            msgValue:        msgValue,
            numOfRuns:       numOfRuns
        }));
    }

    function _loopLzReceive(LzReceiveArgs memory a) internal {
        Origin memory origin = Origin({
            srcEid: a.srcEid,
            sender: bytes32(uint256(uint160(a.sender))),
            nonce:  1
        });

        bytes32 baseGuid = keccak256(
            abi.encodePacked(a.srcEid, a.sender, a.dstEid, a.receiver, block.timestamp)
        );

        // Fund the receiver (NativeOFTAdapter needs native ETH to unlock) and the
        // prank'd endpoint (caller of record for value transfers).
        vm.deal(a.receiver,        10 ether);
        vm.deal(a.endpointAddress, a.numOfRuns * a.msgValue + 1 ether);

        uint256 totalGas;
        uint256 minGas = type(uint256).max;
        uint256 maxGas;
        uint256 runs;

        for (uint256 i = 0; i < a.numOfRuns; i++) {
            origin.nonce = uint64(i + 1);
            bytes32 runGuid = keccak256(abi.encodePacked(baseGuid, i));

            uint256 gasBefore = gasleft();
            vm.prank(a.endpointAddress);
            try ILayerZeroReceiver(a.receiver).lzReceive{ value: a.msgValue }(
                origin, runGuid, a.message, address(0), ""
            ) {
                uint256 gasUsed = gasBefore - gasleft();
                totalGas += gasUsed;
                if (gasUsed < minGas) minGas = gasUsed;
                if (gasUsed > maxGas) maxGas = gasUsed;
                runs++;
            } catch Error(string memory reason) {
                console.log("Run %d: lzReceive reverted: %s", i, reason);
            } catch (bytes memory reason) {
                console.log("Run %d: lzReceive reverted (raw)", i);
                console.logBytes(reason);
            }
        }

        _printResults("lzReceive", runs, totalGas, minGas, maxGas);
    }

    // ── lzReceive profiler (cold-recipient variant) ────────────────────────────
    //
    // Same as run_lzReceive, but synthesizes a fresh recipient address every run
    // so each iteration writes a brand-new balance storage slot (cold SSTORE
    // 0→nonzero, ~20k gas). This matches production reality — every user's first
    // incoming transfer is a cold write. Use this to size enforced gas, not the
    // warm-path `run_lzReceive` which severely underestimates.

    function run_lzReceive_cold(
        string  calldata rpcUrl,
        address          endpointAddress,
        uint32           srcEid,
        address          sender,
        uint32           dstEid,
        address          receiver,
        uint64           amountSD,
        uint256          msgValue,
        uint256          numOfRuns
    ) external {
        vm.createSelectFork(rpcUrl);
        _loopLzReceiveCold(LzReceiveColdArgs({
            endpointAddress: endpointAddress,
            srcEid:          srcEid,
            sender:          sender,
            dstEid:          dstEid,
            receiver:        receiver,
            amountSD:        amountSD,
            msgValue:        msgValue,
            numOfRuns:       numOfRuns
        }));
    }

    function _loopLzReceiveCold(LzReceiveColdArgs memory a) internal {
        Origin memory origin = Origin({
            srcEid: a.srcEid,
            sender: bytes32(uint256(uint160(a.sender))),
            nonce:  1
        });

        bytes32 baseGuid = keccak256(
            abi.encodePacked(a.srcEid, a.sender, a.dstEid, a.receiver, block.timestamp)
        );

        vm.deal(a.receiver,        10 ether);
        vm.deal(a.endpointAddress, a.numOfRuns * a.msgValue + 1 ether);

        uint256 totalGas;
        uint256 minGas = type(uint256).max;
        uint256 maxGas;
        uint256 runs;

        for (uint256 i = 0; i < a.numOfRuns; i++) {
            origin.nonce = uint64(i + 1);
            bytes32 runGuid = keccak256(abi.encodePacked(baseGuid, i));

            // Fresh recipient every iteration → guaranteed cold balance slot.
            address freshTo = address(uint160(uint256(
                keccak256(abi.encode("cold-recipient", i, a.receiver))
            )));
            bytes memory iterMsg = abi.encodePacked(
                bytes32(uint256(uint160(freshTo))),
                a.amountSD
            );

            uint256 gasBefore = gasleft();
            vm.prank(a.endpointAddress);
            try ILayerZeroReceiver(a.receiver).lzReceive{ value: a.msgValue }(
                origin, runGuid, iterMsg, address(0), ""
            ) {
                uint256 gasUsed = gasBefore - gasleft();
                totalGas += gasUsed;
                if (gasUsed < minGas) minGas = gasUsed;
                if (gasUsed > maxGas) maxGas = gasUsed;
                runs++;
            } catch Error(string memory reason) {
                console.log("Run %d: lzReceive(cold) reverted: %s", i, reason);
            } catch (bytes memory reason) {
                console.log("Run %d: lzReceive(cold) reverted (raw)", i);
                console.logBytes(reason);
            }
        }

        _printResults("lzReceive (cold)", runs, totalGas, minGas, maxGas);
    }

    // ── lzCompose profiler ─────────────────────────────────────────────────────

    function run_lzCompose(
        string  calldata rpcUrl,
        address          endpointAddress,
        uint32           srcEid,
        address          sender,
        uint32           dstEid,
        address          receiver,
        address          composer,
        bytes   calldata composeMsg,
        uint256          msgValue,
        uint256          numOfRuns
    ) external {
        vm.createSelectFork(rpcUrl);
        _loopLzCompose(LzComposeArgs({
            endpointAddress: endpointAddress,
            srcEid:          srcEid,
            sender:          sender,
            dstEid:          dstEid,
            receiver:        receiver,
            composer:        composer,
            composeMsg:      composeMsg,
            msgValue:        msgValue,
            numOfRuns:       numOfRuns
        }));
    }

    function _loopLzCompose(LzComposeArgs memory a) internal {
        bytes32 baseGuid = keccak256(
            abi.encodePacked(a.srcEid, a.sender, a.dstEid, a.receiver, block.timestamp)
        );

        // Composer's lzCompose is guarded by msg.sender == endpoint; prank and fund both.
        vm.deal(a.composer,        1 ether);
        vm.deal(a.endpointAddress, a.numOfRuns * a.msgValue + 1 ether);

        uint256 totalGas;
        uint256 minGas = type(uint256).max;
        uint256 maxGas;
        uint256 runs;

        for (uint256 i = 0; i < a.numOfRuns; i++) {
            bytes32 runGuid = keccak256(abi.encodePacked(baseGuid, i));

            uint256 gasBefore = gasleft();
            vm.prank(a.endpointAddress);
            // _from must be the dest-chain OApp that called endpoint.sendCompose (i.e. receiver).
            try IOAppComposer(a.composer).lzCompose{ value: a.msgValue }(
                a.receiver, runGuid, a.composeMsg, address(0), ""
            ) {
                uint256 gasUsed = gasBefore - gasleft();
                totalGas += gasUsed;
                if (gasUsed < minGas) minGas = gasUsed;
                if (gasUsed > maxGas) maxGas = gasUsed;
                runs++;
            } catch Error(string memory reason) {
                console.log("Run %d: lzCompose reverted: %s", i, reason);
            } catch (bytes memory reason) {
                console.log("Run %d: lzCompose reverted (raw)", i);
                console.logBytes(reason);
            }
        }

        _printResults("lzCompose", runs, totalGas, minGas, maxGas);
    }

    // ── Internal ───────────────────────────────────────────────────────────────

    function _printResults(
        string memory fn,
        uint256 runs,
        uint256 totalGas,
        uint256 minGas,
        uint256 maxGas
    ) internal pure {
        if (runs == 0) {
            console.log("[%s] All runs reverted - no gas data", fn);
            return;
        }
        uint256 avgGas = totalGas / runs;
        console.log("=== %s Gas Profile ===", fn);
        console.log("  Runs    : %d", runs);
        console.log("  Avg     : %d", avgGas);
        console.log("  Min     : %d", minGas);
        console.log("  Max     : %d", maxGas);
        console.log("");
        console.log("  Recommended enforced gas (avg + 20%% buffer): %d", avgGas * 120 / 100);
    }
}