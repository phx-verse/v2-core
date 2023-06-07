// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { PHX } from "../src/eSpace/PHX.sol";
import { FarmingController } from "../src/eSpace/Farming/FarmingController.sol";
import { PHXRate } from "../src/eSpace/Farming/PHXRate.sol";
import { VotingEscrow } from "../src/eSpace/Farming/VotingEscrow.sol";
import { Proxy1967 } from "../src/utils/Proxy1967.sol";
import "forge-std/console.sol";

contract LPFarmingTest is Test {
    address public phxTreasury = address(1111);
    address public user2 = address(1112);
    address public user3 = address(1113);
    address public user4 = address(1114);

    PHX public phx;
    FarmingController public farmingController;
    PHXRate public phxRate;
    VotingEscrow public votingEscrow;
    ERC20PresetMinterPauser public lpToken;

    function setUp() public {
        // init phx
        phx = new PHX(phxTreasury);

        vm.startPrank(phxTreasury);
        phx.transfer(user2, 1000_000 ether);
        phx.transfer(user3, 1000_000 ether);
        phx.transfer(user4, 1000_000 ether);
        vm.stopPrank();

        // init lp token
        lpToken = new ERC20PresetMinterPauser("cCFX/CFX LP", "LPT");
        lpToken.mint(phxTreasury, 1000_000_000 ether);

        // init phxRate
        PHXRate phxRateImpl = new PHXRate();
        PHXRate.Rate[] memory rates = new PHXRate.Rate[](2);
        rates[0] = PHXRate.Rate(block.timestamp + 1 days, 1000);
        rates[1] = PHXRate.Rate(block.timestamp + 365 days, 0);
        Proxy1967 _phxRate = new Proxy1967(address(phxRateImpl), abi.encodeWithSelector(PHXRate.initialize.selector, rates));
        phxRate = PHXRate(address(_phxRate));

        // init votingEscrow
        VotingEscrow votingEscrowImpl = new VotingEscrow();
        Proxy1967 _votingEscrow = new Proxy1967(address(votingEscrowImpl), abi.encodeWithSignature("initialize(string,string,uint8,address)", "PHX votes", "PHXV", 18, address(phx)));
        votingEscrow = VotingEscrow(address(_votingEscrow));

        // init farmingController
        FarmingController farmingControllerImpl = new FarmingController();
        Proxy1967 _controller = new Proxy1967(address(farmingControllerImpl), abi.encodeWithSignature("initialize(address,address,address,uint256,address)", address(votingEscrow), address(phxRate), address(phx), block.timestamp, address(lpToken)));
        farmingController = FarmingController(address(_controller));
    }

    function testPhxRateCalculateReward() public {
        uint256 reward = phxRate.calculateReward(block.timestamp, block.timestamp + 1 days);
        assertEq(reward, 0);

        reward = phxRate.calculateReward(block.timestamp, block.timestamp + 2 days);
        assertEq(reward, 1000 * 1 days);

        reward = phxRate.calculateReward(block.timestamp + 365 days, block.timestamp + 366 days);
        assertEq(reward, 0);

        reward = phxRate.calculateReward(block.timestamp, block.timestamp + 366 days);
        assertEq(reward, 1000 * 364 days);
    }

    function testVotingEscrow() public {
        vm.startPrank(user2);

        phx.approve(address(votingEscrow), 2 ether);
        votingEscrow.createLock(1 ether, block.timestamp + 100 days);
        (uint256 amount, uint256 unlockTime) = votingEscrow.userInfo(user2);
        assertEq(amount, 1 ether);
        assertEq(unlockTime, _adjustedTime(block.timestamp + 100 days));

        votingEscrow.increaseAmount(user2, 1 ether);
        (amount, unlockTime) = votingEscrow.userInfo(user2);
        assertEq(amount, 2 ether);

        votingEscrow.increaseUnlockTime(block.timestamp + 200 days);
        (amount, unlockTime) = votingEscrow.userInfo(user2);
        assertEq(unlockTime, _adjustedTime(block.timestamp + 200 days));
        vm.stopPrank();
    }

    function _adjustedTime(uint256 x) internal pure returns (uint256) {
        return (x / 1 weeks) * 1 weeks;
    }

}
