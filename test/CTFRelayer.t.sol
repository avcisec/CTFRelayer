// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;


import { Test, console2 } from "forge-std/Test.sol";
import { CTFRelayer,MessagingFee } from "contracts/CTFRelayer.sol";

import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import { ConditionalTokens } from "./mocks/ConditionalTokens.sol";
import { IConditionalTokens } from "interfaces/IConditionalTokens.sol";

contract LzOperationsTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 private aEid = 1;
    uint32 private bEid = 2;
    bytes32 private questionId = keccak256(abi.encodePacked("questionId"));
    uint8 private outcomeSlotCount = 2;
    uint[] private payouts = [1, 2];
    CTFRelayer public lzReceiver;
    CTFRelayer public lzSender;
    string private uri = "conditionalTokens";
    ConditionalTokens public conditionalTokens;
    address private userA = makeAddr("userA");
    address private userB = makeAddr("userB");
    address private CTADMIN = makeAddr("CTADMIN");
    address private oracle = makeAddr("oracle");
    uint256 private initialBalance = 100 ether;

    function setUp() public virtual override {

        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.deal(CTADMIN, 1000 ether);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);
        
        vm.prank(CTADMIN);
        conditionalTokens = new ConditionalTokens(uri);

       lzSender = CTFRelayer(_deployOApp(type(CTFRelayer).creationCode, abi.encode(address(endpoints[aEid]), address(this),address(conditionalTokens))));
       lzReceiver = CTFRelayer(_deployOApp(type(CTFRelayer).creationCode, abi.encode(address(endpoints[bEid]), address(this),address(conditionalTokens))));

       address[] memory oapps = new address[](2);
       oapps[0] = address(lzSender);
       oapps[1] = address(lzReceiver);
       this.wireOApps(oapps);

        vm.startPrank(CTADMIN);
        conditionalTokens.grantRole(conditionalTokens.DEFAULT_ADMIN_ROLE(), address(lzReceiver));
        conditionalTokens.grantRole(conditionalTokens.DEFAULT_ADMIN_ROLE(), address(lzSender));
        vm.stopPrank();
    }

    /********** Constructor Tests **********/

    function test_constructor() public {

        assertEq(lzSender.owner(), address(this));
        assertEq(lzReceiver.owner(), address(this));
        assertEq(address(lzSender.endpoint()), address(endpoints[aEid]));
        assertEq(address(lzReceiver.endpoint()), address(endpoints[bEid]));
        assertEq(address(lzSender.CTF()), address(conditionalTokens));
        assertEq(address(lzReceiver.CTF()), address(conditionalTokens));
    }

    /********** PrepareCondition Tests **********/

    function test_prepareCondition() public {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        MessagingFee memory fee = lzSender.quotePrepareCondition(bEid,questionId, outcomeSlotCount, options, false);

        vm.prank(userA);
        lzSender.prepareCondition{value: fee.nativeFee}(bEid,questionId, outcomeSlotCount, options);
        verifyPackets(bEid, addressToBytes32(address(lzReceiver)));
        assertEq(conditionalTokens.getOutcomeSlotCount(conditionalTokens.getConditionId(address(lzReceiver), questionId, outcomeSlotCount)), outcomeSlotCount);
    }


    function test_quotePrepareCondition() public {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        bool payInLzToken = false;
        MessagingFee memory quotefee = lzSender.quotePrepareCondition(bEid,questionId,outcomeSlotCount,options,payInLzToken);
        
        uint256 userBalanceBefore = userA.balance;

        vm.prank(userA);
        lzSender.prepareCondition{value: 1 ether}(bEid,questionId, outcomeSlotCount, options);

        uint256 userBalanceAfter = userA.balance;
        assertEq(userBalanceBefore - userBalanceAfter, quotefee.nativeFee);
    }

    /********** ReportPayouts Tests **********/


    function test_quoteReportPayouts() public {
        // prepare a condition
        test_prepareCondition();

        // build options
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        // set the payInLzToken boolean
        bool payInLzToken = false;

        // check the messaging fee
        MessagingFee memory fee = lzSender.quoteReportPayouts(bEid, questionId, payouts, options, payInLzToken);

        // pay 1 eth for messaging and layerZero will payback the rest.
        vm.prank(userA);
        uint256 userBalanceBefore = userA.balance;
        lzSender.reportPayouts{value: 1 ether}(bEid,questionId, payouts, options);
        uint256 userBalanceAfter = userA.balance;
        // check if quoteReportPayouts fee == fee paid by user
        assertEq(userBalanceBefore - userBalanceAfter, fee.nativeFee);
    }


    function test_ReportPayoutWithoutPreparing() public {
        // build options
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        // set the payInLzToken boolean
        bool payInLzToken = false;

        //check the messaging fee
        MessagingFee memory fee = lzSender.quoteReportPayouts(bEid,questionId, payouts, options, payInLzToken);

        vm.prank(userA);
        uint outcomeSlotCountBefore = conditionalTokens.getOutcomeSlotCount(conditionalTokens.getConditionId(address(lzReceiver), questionId, outcomeSlotCount));
        lzSender.reportPayouts{value: fee.nativeFee}(bEid,questionId, payouts, options);
        uint outcomeSlotCountAfter = conditionalTokens.getOutcomeSlotCount(conditionalTokens.getConditionId(address(lzReceiver), questionId, outcomeSlotCount));
        assertEq(outcomeSlotCountBefore,0); // condition hasn't prepared.
        assertEq(outcomeSlotCountAfter,0); // condition not resolved because doesn't exist. 

    }


    function test_reportPayoutsAfterPrepareCondition() public {
        uint outcomeSlotCountBefore = conditionalTokens.getOutcomeSlotCount(conditionalTokens.getConditionId(address(lzReceiver), questionId, outcomeSlotCount));
        test_prepareCondition();
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        MessagingFee memory fee = lzSender.quoteReportPayouts(bEid,questionId, payouts, options, false);
        vm.prank(userA);
        lzSender.reportPayouts{value: fee.nativeFee}(bEid,questionId, payouts, options);
        uint outcomeSlotCountAfter = conditionalTokens.getOutcomeSlotCount(conditionalTokens.getConditionId(address(lzReceiver), questionId, outcomeSlotCount));
        assertEq(outcomeSlotCountBefore,0);
        assert(outcomeSlotCountAfter > 0);
        verifyPackets(bEid, addressToBytes32(address(lzReceiver)));

    }

    function test_reportPayoutOnCTWithoutPreparing() public {
        vm.prank(userA);
        vm.expectRevert("condition not prepared or found");
        conditionalTokens.reportPayouts(questionId,payouts);
    }


}