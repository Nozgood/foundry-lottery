// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    uint256 entranceFee = 5e18;
    uint256 interval = 60; // 60 seconds
    uint256 subscriptionId =
        34454315038717409854187127711103819628859866229620648994410326661620188613650;
    address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 keyHash =
        0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897;
    uint32 callbackGasLimit = 4000;

    function run() external returns (Raffle) {
        vm.startBroadcast();
        Raffle newRaffle = new Raffle(
            entranceFee,
            interval,
            subscriptionId,
            vrfCoordinator,
            keyHash,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return newRaffle;
    }
}
