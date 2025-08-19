// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
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

    function testRaffleRecordsPlayerWhenEntered() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: 0.1 ether}();
        address playerRecorded = raffle.getPlayer(0);
        // Assert
        assertEq(playerRecorded, address(PLAYER));
    }

    function testRaffleEventEmittedWhenEntered() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        // Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: 0.1 ether}();
    }
}
