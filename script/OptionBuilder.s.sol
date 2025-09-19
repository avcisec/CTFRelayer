pragma solidity 0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract OptionsScript is Script {
    using OptionsBuilder for bytes;

    function setUp() public {}

    function run() public {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        console2.logBytes(options);
    }
}