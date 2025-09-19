// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;


interface ICTFRelayer {

    struct PrepareConditionMessage {
        bytes32 questionId;
        uint8 outcomeSlotCount;
    }

    struct ReportPayoutsMessage {
        bytes32 questionId;
        uint[] payouts;
    }

    enum Action {
        PrepareCondition,
        ReportPayouts
    }

    /// @dev Emitted when the prepareCondition is sent
    event PrepareConditionSent(uint32 indexed dstEid, bytes32 indexed questionId, uint256 indexed outcomeSlotCount);
    /// @dev Emitted when the reportPayouts is sent
    event ReportPayoutsSent(uint32 indexed dstEid, bytes32 indexed questionId, uint256[] indexed payouts);

    function prepareCondition(uint32 _dstEid, bytes32 _questionId, uint8 _outcomeSlotCount, bytes calldata _options) external payable;
    function reportPayouts(uint32 _dstEid, bytes32 _questionId, uint[] calldata _payouts, bytes calldata _options) external payable;

}