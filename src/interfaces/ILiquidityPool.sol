// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface ILiquidityPool {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
    function lendBySWCFX(uint256 _amount) external;
    function repayForSWCFX() external payable;
    function totalLiquidity() external view returns (uint256);
}
