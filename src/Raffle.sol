// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {console2} from "forge-std/Script.sol";

// TODO: make Raffle contract inherits from VRF contract

/// @title a sample Raffle contract
/// @author nowdev
/// @notice This contract has a learning purpose, it does not aims to be used in production
/// @dev
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    error Raffle__InsufficientEntranceFee(uint256 send, uint256 required);
    error Raffle__InsufficientInterval();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUMBER_OF_WORDS = 1;

    // i_ for immutable
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash; // from chainlink doc for ETH sepolia (2 gwei key hash): 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897
    uint256 private immutable i_subscriptionId; // subId of my own(metamask): 34454315038717409854187127711103819628859866229620648994410326661620188613650
    uint32 private immutable i_callbackGasLimit;

    // s_ for state variable
    address payable[] private s_players; // payable to allow addresses to receive ether
    uint256 private s_lastTimestamp;
    uint256 private s_subscriptionId;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // NOTE: i have to use the constructor of the contract i inherits from

    // WARN: the address of the Coordinator is hardcoded for SEPOLIA
    // 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B

    constructor(
        uint256 entranceFee,
        uint256 interval,
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;

        s_raffleState = RaffleState.OPEN;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEntranceFee(msg.value, i_entranceFee);
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function _checkUpkeep()
        internal
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        console2.log("last timestamp:", s_lastTimestamp);
        console2.log("time passed: ", timeHasPassed);
        bool isRaffleOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded =
            timeHasPassed &&
            isRaffleOpen &&
            hasBalance &&
            hasPlayers;

        return (upkeepNeeded, "");
    }

    /// @dev this is the function the Chainlink nodes will call to check if it's time to PickWinner
    /// the following conditions need to be statisfied to pick the winner:
    ///     1. the time interval has passed between raffle runs
    ///     2. the lottery status is on OPEN state
    ///     3. the contract has ETH
    ///     4. the subscription has LINK (needed to pick a random number)
    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        return _checkUpkeep();
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = _checkUpkeep();
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        // we request the random number with this call
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS, // 3 is the default value
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMBER_OF_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        // NOTE: this event is redundant, the VrfCoordinnator already emit one, but we keep it to facilitate tests
        emit RequestedRaffleWinner(requestId);
    }

    // implementation of fullfillRandomWords function
    // NOTE: since the random number generated by VRF is big (like 380479372098309), we use modulo to be sure we have
    // a number in the range of players array length
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        emit WinnerPicked(s_recentWinner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
