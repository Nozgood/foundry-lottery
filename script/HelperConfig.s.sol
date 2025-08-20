// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant SEPOLIA_ETH_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId(uint256 chainId);

    /// @dev NetworkConfig contains the params we need to init a new Raffle contract
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        uint256 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /// @dev in the constructor, we check the chainId to dynamically create a config
    /// in function of the blockchain we use
    constructor() {
        networkConfigs[SEPOLIA_ETH_CHAIN_ID] = getSepoliaETHConfig();
        // networkConfigs[LOCAL_CHAIN_ID] = getAnvilConfig();
    }

    function getSepoliaETHConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            entranceFee: 5e18,
            interval: 30,
            subscriptionId: 0, // 34454315038717409854187127711103819628859866229620648994410326661620188613650,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });

        return ethConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken mockLinkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            subscriptionId: 0,
            vrfCoordinator: address(mockVrfCoordinator),
            keyHash: 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897,
            callbackGasLimit: 500000,
            link: address(mockLinkToken)
        });

        return localNetworkConfig;
    }

    function getNetworkConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getAnvilConfig();
        }

        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }

        revert HelperConfig__InvalidChainId(chainId);
    }

    function getNetworkConfig() public returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }
}
