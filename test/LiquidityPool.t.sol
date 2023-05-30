// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "forge-std/Test.sol";
import "../src/eSpace/LiquidityPool.sol";
import "../src/eSpace/SWCFX.sol";
import "../src/utils/ProxyAdmin.sol";
import "../src/utils/TransparentProxy.sol";

contract LiquidityPoolTest is Test {
    ProxyAdmin public admin;
    TransparentUpgradeableProxy public proxy;
    LiquidityPool public lp;
    SWCFX public swcfx;
    address public user1 = address(1111);
    address public user2 = address(1112);
    address public fake_swcfx_bridge = address(1113);

    function setUp() public {
        // deploy swcfx
        admin = new ProxyAdmin();
        SWCFX swcfx_impl = new SWCFX();
        bytes memory data = abi.encodeWithSignature("initialize(string,string)", "PoS Wrapped CFX", "sWCFX");
        proxy = new TransparentUpgradeableProxy(address(swcfx_impl), address(admin), data);
        swcfx = SWCFX(payable(proxy));
        swcfx.setCoreBridge(fake_swcfx_bridge);

        // deploy liquidity pool
        lp = new LiquidityPool();
        lp.setSWCFX(address(swcfx));

        swcfx.setLiquidPool(address(lp));

        vm.deal(user1, 1000_000_000 ether);
        vm.deal(user2, 1000_000_000 ether);
    }

    function testLiquidityPoolDeposit2Widthdraw() public {
        vm.startPrank(user1);

        lp.deposit{value: 10000 ether}();
        assertEq(lp.balances(user1), 10000 ether);

        lp.withdraw(1000 ether);
        assertEq(lp.balances(user1), 9000 ether);

        assertEq(address(lp).balance, 9000 ether);
        
        vm.stopPrank();

        vm.startPrank(user2);
        assertEq(swcfx.balanceOf(user2), 0);

        swcfx.deposit{value: 10000 ether}();
        assertEq(swcfx.balanceOf(user2), 10000 ether);
        assertEq(address(swcfx).balance, 5000 ether);

        swcfx.approve(address(swcfx), 10000 ether);
        swcfx.withdraw(10000 ether);
        assertEq(address(swcfx).balance, 0 ether);
        assertEq(address(lp).balance, 4000 ether);
        assertEq(swcfx.balanceOf(user2), 0 ether);

        vm.stopPrank();

        vm.startPrank(fake_swcfx_bridge);
        assertEq(swcfx.totalLend(), 5000 ether);
        assertEq(swcfx.balanceOf(address(lp)), 5000 ether);
        assertEq(fake_swcfx_bridge.balance, 5000 ether);
        swcfx.handleRedeem{value: 5000 ether}();
        assertEq(swcfx.totalLend(), 0 ether);
        assertEq(swcfx.balanceOf(address(lp)), 0 ether);
        vm.stopPrank();
    }

}