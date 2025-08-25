// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {console2} from "forge-std/Script.sol";

contract DeployRaffle is Script {
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscriptionScript = new CreateSubscription();
            (
                networkConfig.subscriptionId,
                networkConfig.vrfCoordinator
            ) = createSubscriptionScript.createSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.account
            );

            FundSubscription fundSubscriptionScript = new FundSubscription();
            fundSubscriptionScript.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link,
                networkConfig.account
            );
        }

        vm.startBroadcast(networkConfig.account);
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
        addConsumerScript.addConsumer(
            address(newRaffle),
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.account
        );

        return (newRaffle, helperConfig);
    }

    function run() public {
        deployRaffle();
    }
}
