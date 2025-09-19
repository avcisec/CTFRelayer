// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {CTFRelayer} from "contracts/CTFRelayer.sol";

contract deployCTFRelayer is Script {
    CTFRelayer ctfRelayer;


    function run() external returns (CTFRelayer) {

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK_BASE");
        address baseEndpoint = vm.envAddress("BASE_SEPOLIA_ENDPOINT_V2");
        address deployer = vm.envAddress("DEPLOYER_BASE");
        address ctf = vm.envAddress("CTF_ARBITRUM_SEPOLIA");

        vm.startBroadcast(deployerPrivateKey);
        ctfRelayer = new CTFRelayer(baseEndpoint,deployer,ctf);
        
        vm.stopBroadcast();

        return ctfRelayer;
    }

}