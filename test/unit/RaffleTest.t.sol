// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {console2} from "forge-std/Script.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 private entranceFee;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

        entranceFee = raffle.getEntranceFee();
    }

    function testRaffleStateStartsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testGetEntranceFee() public view {
        assert(0.01 ether == raffle.getEntranceFee());
    }

    function testEnterRaffleNotEnoughValue() public {
        vm.prank(PLAYER);

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__InsufficientEntranceFee.selector,
                0 ether,
                0.01 ether
            )
        );
        raffle.enterRaffle();
    }

    function testEnterRaffleRecordsPlayerWhenEntered() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        // Assert
        assertEq(playerRecorded, address(PLAYER));
    }

    function testEnterRaffleEventEmittedWhenEntered() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        // Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testEnterRaffleDontAllowPlayerWhileCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseWithoutTimePassed() public {
        // vm.warp(block.timestamp + 29);
        // console2.log("block timestamp: ", block.timestamp);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIsNeeded() public {
        // Arrange
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }
}
