// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract IDO is Ownable {
    ERC20 public  phx;
    uint256 public price; // price = phx / cfx
    uint256 constant public RATIO_BASE = 10000;

    constructor(address _phx) {
        phx = ERC20(_phx);
        price = 100000;
    }

    function transfer(address _to, uint256 _amount) public onlyOwner {
        phx.transfer(_to, _amount);
    }

    receive() external payable {
        uint256 amount = _calAmount(msg.value);
        require(amount > 0, "IDO: amount is zero");
        require(amount <= 10000 ether, "IDO: amount is too large");
        require(phx.balanceOf(address(this)) >= amount, "IDO: insufficient balance");
        phx.transfer(msg.sender, amount);
    }

    function _calAmount(uint256 _amount) internal view returns (uint256) {
        return _amount * price / RATIO_BASE;
    }
}
