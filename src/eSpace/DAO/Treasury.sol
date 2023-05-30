// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PHXTreasury is Ownable {
    ERC20 public  phx;

    function setPhx(address _phx) public onlyOwner {
        phx = ERC20(_phx);
    }

    function transfer(address _to, uint256 _amount) public onlyOwner {
        phx.transfer(_to, _amount);
    }
}
