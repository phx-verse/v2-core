// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILiquidityPool } from "../interfaces/ILiquidityPool.sol";

interface ILender is IERC20, ILiquidityPool {
    function receiveLend() external payable;
}

contract LiquidityPool is Ownable {
    uint256 constant RATIO_BASE = 10000;
    
    ILender public swcfx;

    uint256 public totalLiquidity;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public swcfxLendAmounts;

    function initialize() public {}

    function deposit() public payable {
        require(msg.value > 0, "deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        totalLiquidity += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "withdraw amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "insufficient balance");
        require(address(this).balance >= _amount, "insufficient liquidity");
        balances[msg.sender] -= _amount;
        totalLiquidity -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function lendBySWCFX(uint256 _amount) public {
        require(_amount > 0, "lend amount must be greater than 0");
        require(address(this).balance >= _amount, "insufficient balance");
        require(swcfx.allowance(msg.sender, address(this)) >= _amount, "insufficient allowance");
        swcfxLendAmounts[msg.sender] += _amount;
        swcfx.transferFrom(msg.sender, address(this), _amount);
        swcfx.receiveLend{value: _amount}();
    }

    function repayForSWCFX() public payable {
        require(msg.value > 0, "lend amount must be greater than 0");
        require(swcfxLendAmounts[msg.sender] >= msg.value, "insufficient balance");
        swcfxLendAmounts[msg.sender] -= msg.value;
        swcfx.transfer(msg.sender, msg.value);
    }

    function setSWCFX(address _swcfx) public onlyOwner {
        swcfx = ILender(_swcfx);
    }
}
