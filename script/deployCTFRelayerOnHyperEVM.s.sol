// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {CTFRelayer} from "contracts/CTFRelayer.sol";

contract deployCTFRelayer is Script {
    CTFRelayer ctfRelayer;


    function run() external returns (CTFRelayer) {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK_HYPEREVM");
        address baseEndpoint = vm.envAddress("HYPEREVM_TESTNET_ENDPOINT_V2");
        address deployer = vm.envAddress("DEPLOYER_HYPEREVM");
        address ctf = vm.envAddress("CTF");

        vm.startBroadcast(deployerPrivateKey);
        ctfRelayer = new CTFRelayer(baseEndpoint,deployer,ctf);
        
        vm.stopBroadcast();

        return ctfRelayer;
    }

}