// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/utils/Proxy1967.sol";
import "../src/eSpace/CCFX.sol";
import "../src/eSpace/Farming/FarmingPool.sol";
import "../src/eSpace/PHX.sol";

contract CCFXTest is Test {
    address public user1 = address(1111);
    address public user2 = address(1112);
    address public fake_ccfx_bridge = address(1113);

    CCFX public ccfx;
    PHX public phx;
    FarmingPool public farmingPool;

    function setUp() public {
        phx = new PHX(user1);

        FarmingPool farmingPoolImpl = new FarmingPool();
        Proxy1967 p1 = new Proxy1967(address(farmingPoolImpl), abi.encodeWithSignature("initialize()"));
        farmingPool = FarmingPool(address(p1));
        farmingPool.setPHX(address(phx));

        CCFX ccfxImpl = new CCFX();
        Proxy1967 p2 = new Proxy1967(address(ccfxImpl), abi.encodeWithSignature("initialize()"));
        ccfx = CCFX(address(p2));
        ccfx.setFarmingPool(address(farmingPool));
        ccfx.setCoreBridge(fake_ccfx_bridge);

        farmingPool.setCCFX(address(ccfx));

        vm.deal(user1, 1000_000_000 ether);
        vm.deal(user2, 1000_000_000 ether);
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user1);

        ccfx.deposit{value: 10000 ether}();
        assertEq(ccfx.balanceOf(user1), 10000 ether);

        ccfx.redeem(1000 ether);
        assertEq(ccfx.balanceOf(user1), 9000 ether);
        vm.stopPrank();

        vm.startPrank(fake_ccfx_bridge);
        assertEq(ccfx.firstRedeemAmount(), 1000 ether);
        ccfx.handleRedeem{value: 1000 ether}();
        assertEq(ccfx.firstRedeemAmount(), 0);
        assertEq(ccfx.totalRedeemedAssets(), 0);
        vm.stopPrank();

        vm.prank(user1);
        ccfx.withdraw(1000 ether);
        assertEq(user1.balance, 1000_000_000 ether - 9000 ether);
    }

}
