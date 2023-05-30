// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/eSpace/WCFX10.sol";

contract WCFXTest is Test {
    WCFX10 public wcfx;
    address public testAddr = 0x1111111111111111111111111111111111111111;
    address public testAddr2 = 0x2222222211111111111111111111111111111111;

    function setUp() public {
        wcfx = new WCFX10('Wrapped CFX', 'WCFX');
        vm.deal(testAddr, 100 ether);
    }

    function testDeposit() public {
        // test deposit method
        vm.startPrank(testAddr);
        wcfx.deposit{value: 100}();
        assertEq(wcfx.balanceOf(testAddr), 100);

        // test directly send eth to contract
        (bool success,) = address(wcfx).call{value: 100}("");
        assertEq(wcfx.balanceOf(testAddr), 200);
        assertEq(success, true);

        // test depositTo method
        wcfx.depositTo{value: 100}(testAddr2);
        assertEq(wcfx.balanceOf(testAddr2), 100);

        assertEq(testAddr.balance, 100 ether - 300);
        assertEq(wcfx.totalSupply(), 300);
    }

    function testWithdraw() public {
        assertEq(testAddr.balance, 100 ether);

        vm.prank(testAddr);
        wcfx.deposit{value: 500}();
        assertEq(wcfx.balanceOf(testAddr), 500);

        vm.prank(testAddr);
        wcfx.withdraw(100);
        assertEq(wcfx.balanceOf(testAddr), 400);
        assertEq(testAddr.balance, 100 ether - 400);

        vm.prank(testAddr);
        wcfx.withdrawTo(payable(testAddr2), 100);
        assertEq(wcfx.balanceOf(testAddr), 300);
        assertEq(testAddr2.balance, 100);

        vm.prank(testAddr);
        wcfx.approve(testAddr2, 100);
        vm.prank(testAddr2);
        wcfx.withdrawFrom(testAddr, payable(testAddr2), 100);
        assertEq(wcfx.balanceOf(testAddr), 200);

        assertEq(testAddr2.balance, 200);
        assertEq(wcfx.allowance(testAddr, testAddr2), 0);
    }

}
