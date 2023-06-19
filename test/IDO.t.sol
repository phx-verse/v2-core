// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";
import "../src/eSpace/DAO/IDO.sol";
import "../src/eSpace/PHX.sol";

contract IDOTest is Test {
    PHX public phx;
    IDO public ido;
    address public user1 = address(1111);
    address public user2 = address(1112);

    function setUp() public {
        phx = new PHX(user1);
        ido = new IDO(address(phx));

        vm.deal(user1, 1000_000_000 ether);
        vm.deal(user2, 1000_000_000 ether);

        vm.prank(user1);
        phx.transfer(address(ido), 1000_000 ether);
    }

    function testPurchage() public {
        vm.startPrank(user2);
        address payable _to = payable(address(ido));
        (bool sent, bytes memory data) = _to.call{value: 1 ether, gas: 39000}("");
        require(sent, "Failed to send Ether");

        assertEq(phx.balanceOf(user2), 10 ether);
    }

}
