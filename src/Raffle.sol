// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// 2. import statements

// 4. errors

error Raffle__InsufficientEntranceFee(uint256 send, uint256 required);

// 5. interfaces

// 6. libraries

// 7. contracts

/// @title a sample Raffle contract
/// @author nowdev
/// @notice This contract has a learning purpose, it does not aims to be used in production
/// @dev
contract Raffle {
    // i_ for immutable
    uint256 private immutable i_entranceFee;

    // s_ for state variable
    // payable to allow addresses to receive ether
    address payable[] private s_players;

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
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    // enterRaffle => a user participate to the raffle, pay the fee etc ...
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEntranceFee(msg.value, i_entranceFee);
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // pickWinner => we select the winner of the raffle
    function pickWinner() public {}
}
