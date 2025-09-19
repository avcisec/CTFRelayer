//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";
import { ICTFRelayer } from "../interfaces/ICTFRelayer.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";


/**
 * @title CTFRelayer
 * @author 0xBlockMamba
 * @notice This contract relays condition preparation and resolution actions of UMA CTF Adapter to CTF on hyperEVM.
 */
contract CTFRelayer is OApp, OAppOptionsType3, ICTFRelayer {
     using OptionsBuilder for bytes;


    /********** Constants **********/
    
    /// @notice Conditional Tokens Framework
    IConditionalTokens public immutable CTF;

    /********** Constructor **********/

    /// @param _endpoint LayerZero endpoint address
    /// @param _owner Owner address
    constructor(address _endpoint, address _owner, address _ctf) OApp(_endpoint, _owner) Ownable(_owner) {
        CTF = IConditionalTokens(_ctf);
    }

    /********** External Functions **********/


    function prepareCondition(uint32 _dstEid, bytes32 _questionId, uint8 _outcomeSlotCount, bytes calldata _options) external payable {
        // Checks

        // Prepare cross-chain message
        PrepareConditionMessage memory _message = PrepareConditionMessage({
            questionId: _questionId,
            outcomeSlotCount: _outcomeSlotCount
        });
        bytes memory _payload = abi.encode(Action.PrepareCondition,abi.encode(_message));
        // Use provided options or create default
        bytes memory options = _options.length > 0 ? _options : 
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        _lzSend(_dstEid,_payload, options,MessagingFee(msg.value,0),payable(msg.sender));
        emit PrepareConditionSent(_dstEid, _questionId, _outcomeSlotCount);

    }


    function reportPayouts(uint32 _dstEid, bytes32 _questionId, uint[] calldata _payouts, bytes calldata _options) external payable{
        // checks

        // Prepare cross-chain message
        ReportPayoutsMessage memory _message = ReportPayoutsMessage({
            questionId: _questionId,
            payouts: _payouts
        });
        bytes memory _payload = abi.encode(Action.ReportPayouts,abi.encode(_message));
        // Use provided options or create default
        bytes memory options = _options.length > 0 ? _options : 
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        _lzSend(_dstEid,_payload, options,MessagingFee(msg.value,0),payable(msg.sender));
        emit ReportPayoutsSent(_dstEid, _questionId, _payouts);
    }

    /********** Internal Functions **********/

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (Action action, bytes memory data) = abi.decode(_message,(Action, bytes));

        if (action == Action.PrepareCondition) {
            PrepareConditionMessage memory message = abi.decode(data, (PrepareConditionMessage));
            CTF.prepareCondition(message.questionId, message.outcomeSlotCount);
        } else if (action == Action.ReportPayouts) {
            ReportPayoutsMessage memory message = abi.decode(data, (ReportPayoutsMessage));
            require(!_conditionPrepared(message.questionId), "Condition Not Prepared.");
            CTF.reportPayouts(message.questionId,message.payouts);
        }
    }

    /********** View & Pure Functions **********/

    function _conditionPrepared(bytes32 _questionId) internal view returns (bool prepared) {
        bytes32 conditionId = CTF.getConditionId(address(this), _questionId, 2);
        uint outcomeSlotCount = CTF.getOutcomeSlotCount(conditionId);
        if (outcomeSlotCount == 0) return false;
        if (outcomeSlotCount > 0) return true; 
    }

    /// @notice Quote the prepareCondition fee
    /// @param _questionId The question ID
    /// @param _outcomeSlotCount The outcome slot count
    /// @param _options The options
    /// @param _payInLzToken The pay in LZ token
    /// @return fee The fee
    function quotePrepareCondition(uint32 _dstEid, bytes32 _questionId, uint8 _outcomeSlotCount, bytes calldata _options, bool _payInLzToken) public view returns (MessagingFee memory fee) {
        
        // Quote cross-chain message
        PrepareConditionMessage memory _message = PrepareConditionMessage({
            questionId: _questionId,
            outcomeSlotCount: _outcomeSlotCount
        });
        bytes memory _payload = abi.encode(Action.PrepareCondition,abi.encode(_message));

        // Use provided options or create default
        bytes memory options = _options.length > 0 ? _options : 
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        fee = _quote(_dstEid, _payload, options, _payInLzToken);
    }

    /// @notice Quote the quoteReportPayouts fee
    /// @param _questionId The question ID
    /// @param _payouts Payout array for condition
    /// @param _options The options
    /// @param _payInLzToken The pay in LZ token
    /// @return fee The fee
    function quoteReportPayouts(uint32 _dstEid, bytes32 _questionId, uint[] calldata _payouts, bytes calldata _options, bool _payInLzToken) public view returns (MessagingFee memory fee) {
        
        // Quote cross-chain message
        ReportPayoutsMessage memory _message = ReportPayoutsMessage({
            questionId: _questionId,
            payouts: _payouts
        });
        bytes memory _payload = abi.encode(Action.ReportPayouts,abi.encode(_message));
        // Use provided options or create default
        bytes memory options = _options.length > 0 ? _options : 
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        fee = _quote(_dstEid, _payload, options, _payInLzToken);
    }
    

    /********** Getter Functions **********/

    function getPrepareConditionFee(uint32 _dstEid, bytes32 _questionId, uint8 _outcomeSlotCount, bytes calldata _options, bool _payInLzToken) public view returns (uint256 nativeFee) {
        MessagingFee memory fee = quotePrepareCondition(_dstEid,_questionId,_outcomeSlotCount,_options,_payInLzToken);
        return fee.nativeFee;
    }

    function getReportPayoutsFee(uint32 _dstEid,bytes32 _questionId, uint[] calldata _payouts, bytes calldata _options, bool _payInLzToken) public view returns (uint256 nativeFee) {
        MessagingFee memory fee = quoteReportPayouts(_dstEid,_questionId,_payouts,_options,_payInLzToken);
        return fee.nativeFee;
    }

}