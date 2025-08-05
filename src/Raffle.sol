// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

error InsufficientEntranceFee(uint256 send, uint256 required);

/// @title a sample Raffle contract
/// @author nowdev
/// @notice This contract has a learning purpose, it does not aims to be used in production
/// @dev
contract Raffle {
    uint256 private immutable i_entranceFee;

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
        require(
            msg.value >= i_entranceFee,
            InsufficientEntranceFee(msg.value, i_entranceFee)
        );
    }

    // pickWinner => we select the winner of the raffle
    function pickWinner() public {}
}
