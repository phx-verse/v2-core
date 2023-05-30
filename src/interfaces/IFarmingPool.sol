// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
interface IFarmingPool {
    function updateYield(address _account) external;
}