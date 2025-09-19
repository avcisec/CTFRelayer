// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {CTFRelayer} from "contracts/CTFRelayer.sol";


contract SetPeers is Script {

    function run() external {
        
        address ctfRelayer = vm.envAddress("CTF_RELAYER_ON_ARBITRUM_SEPOLIA");
        address signer = vm.envAddress("DEPLOYER_ARBITRUM_SEPOLIA");

        (uint32 eid1, bytes32 peer1) = (uint32(vm.envUint("ARBITRUM_SEPOLIA_ENDPOINT_V2_ID")), bytes32(uint256(uint160(vm.envAddress("CTF_RELAYER_ON_ARBITRUM_SEPOLIA")))));
        (uint32 eid2, bytes32 peer2) = (uint32(vm.envUint("BASE_SEPOLIA_ENDPOINT_V2_ID")), bytes32(uint256(uint160(vm.envAddress("CTF_RELAYER_ON_BASE")))));

        vm.startBroadcast(signer);

        CTFRelayer(ctfRelayer).setPeer(eid1, peer1);
        CTFRelayer(ctfRelayer).setPeer(eid2, peer2);

        vm.stopBroadcast();
        
    }
}