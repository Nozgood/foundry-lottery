// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// 2. import statements

// TODO: import Chainlink VRF contract

// 4. errors

error Raffle__InsufficientEntranceFee(uint256 send, uint256 required);
error Raffle__InsufficientInterval();

// 5. interfaces

// 6. libraries

// 7. contracts

// TODO: make Raffle contract inherits from VRF contract

/// @title a sample Raffle contract
/// @author nowdev
/// @notice This contract has a learning purpose, it does not aims to be used in production
/// @dev
contract Raffle {
    // i_ for immutable
    uint256 private immutable i_entranceFee;

    // @dev the duration of lottery in seconds
    uint256 private immutable i_interval;

    // s_ for state variable
    // payable to allow addresses to receive ether
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    event RaffleEntered(address indexed player);

    /*
        order of functions:
            - constructor
            - receive function (if exists)
            - fallback function (if exists)
            - external
            - public
            - internal
            - private
        */

    // at the init of the contract, we set the entrance fee value to the received param;
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    // enterRaffle => a user participate to the raffle, pay the fee etc ...
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEntranceFee(msg.value, i_entranceFee);
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // pickWinner => we select the winner of the raffle
    function pickWinner() external {
        if ((block.timestamp - s_lastTimestamp) > i_interval) {
            revert Raffle__InsufficientInterval();
        }

        // TODO: request the number
        // TODO get the number
    }
}
