// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 private entranceFee;
    address private vrfCoordinator;

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);
        _;
    }

    // WARN: this is not recommended for a real dev environment, but for now, it is OK
    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

        entranceFee = raffle.getEntranceFee();
        vrfCoordinator = helperConfig
            .getNetworkConfigByChainId(block.chainid)
            .vrfCoordinator;
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

    function testEnterRaffleDontAllowPlayerWhileCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseWithoutTimePassed() public view {
        // vm.warp(block.timestamp + 29);
        console2.log("block timestamp: ", block.timestamp);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIsNeeded() public raffleEntered {
        // Arrange

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

    function testPerformUpkeepNotNeeded() public {
        uint256 balance = address(raffle).balance;
        uint256 numberOfPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                balance,
                numberOfPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepEmitEvent() public raffleEntered {
        // Arrange - here the Arrange part is made by raffleEntered modifier

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFulfillRandomWordsCalledOnlyAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsNormalBehavior()
        public
        raffleEntered
        skipFork
    {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i < 4; i++) {
            address newPlayer = address(uint160(i));

            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimestamp();
        uint256 startingBalance = address(uint160(1)).balance;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        address recentWinner = raffle.getRecentWinner();
        uint256 winnerBalance = recentWinner.balance;
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 endingTimestamp = raffle.getLastTimestamp();

        uint256 prize = entranceFee * (additionalEntrants + 1);

        assertEq(winnerBalance, startingBalance + prize);
        assertEq(uint256(raffleState), 0);
        assert(endingTimestamp > startingTimeStamp);
    }
}
