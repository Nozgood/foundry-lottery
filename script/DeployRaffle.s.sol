// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getNetworkConfig();

        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscriptionScript = new CreateSubscription();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                createSubscriptionScript.createSubscription(networkConfig.vrfCoordinator);

            FundSubscription fundSubscriptionScript = new FundSubscription();
            fundSubscriptionScript.fundSubscription(
                networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.link
            );
        }

        vm.startBroadcast();
        Raffle newRaffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.subscriptionId,
            networkConfig.vrfCoordinator,
            networkConfig.keyHash,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumerScript = new AddConsumer();
        addConsumerScript.addConsumer(address(newRaffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId);

        return (newRaffle, helperConfig);
    }

    function run() public {
        deployRaffle();
    }
}
