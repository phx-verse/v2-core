// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { PHXTreasury } from "../src/eSpace/DAO/Treasury.sol";
import { PHX } from "../src/eSpace/PHX.sol";

contract PHXTreasuryTest is Test {
    PHXTreasury public treasury;
    PHX public phx;
    address user = address(111);

    function setUp() public {
        treasury = new PHXTreasury();
        phx = new PHX(address(treasury));
        treasury.setPhx(address(phx));
        vm.deal(user, 100 ether);
    }

    function testTransfer() public {
        assertEq(phx.balanceOf(address(treasury)), 100_000_000 ether);
        treasury.transfer(user, 10 ether);
        assertEq(phx.balanceOf(address(user)), 10 ether);
        assertEq(phx.balanceOf(address(treasury)), 100_000_000 ether - 10 ether);
    }
}
