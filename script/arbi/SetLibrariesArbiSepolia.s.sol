// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/// @title LayerZero Library Configuration Script
/// @notice Sets up send and receive libraries for CTFRelayer messaging
contract SetLibraries is Script {
    function run() external {
        // Load environment variables
        address endpoint = vm.envAddress("ARBITRUM_SEPOLIA_ENDPOINT_V2");    // LayerZero Endpoint address
        address ctfRelayer = vm.envAddress("CTF_RELAYER_ON_ARBITRUM_SEPOLIA");           // CTFRelayer contract address
        uint256 signer = vm.envUint("DEPLOYER_PK_ARBITRUM_SEPOLIA");               // Address with permissions to configure

        // Library addresses
        address sendLib = vm.envAddress("SEND_LIB_ADDRESS_ARBITRUM_SEPOLIA");    // SendUln302 address
        address receiveLib = vm.envAddress("RECEIVE_LIB_ADDRESS_ARBITRUM_SEPOLIA"); // ReceiveUln302 address

        // Chain configurations
        uint32 dstEid = uint32(vm.envUint("BASE_SEPOLIA_ENDPOINT_V2_ID"));         // Destination chain EID
        uint32 srcEid = uint32(vm.envUint("ARBITRUM_SEPOLIA_ENDPOINT_V2_ID"));         // Source chain EID
        uint32 gracePeriod = uint32(vm.envUint("GRACE_PERIOD")); // Grace period for library switch

        vm.startBroadcast(signer);

        // Set send library for outbound messages
        ILayerZeroEndpointV2(endpoint).setSendLibrary(
            ctfRelayer,    // ctfRelayer address
            dstEid,  // Destination chain EID
            sendLib  // SendUln302 address
        );

        // Set receive library for inbound messages
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(
            ctfRelayer,        // ctfRelayer address
            srcEid,      // Source chain EID
            receiveLib,  // ReceiveUln302 address
            gracePeriod  // Grace period for library switch
        );

        vm.stopBroadcast();
    }
}