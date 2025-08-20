// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console2.log("Create subscription for chainId %d", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console2.log("subscriptionID is ", subId);

        return (subId, vrfCoordinator);
    }

    function run() public {}
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether; // = 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getNetworkConfig().subscriptionId;
        address linkToken = helperConfig.getNetworkConfig().link;
    }

    function run() public {}
}
