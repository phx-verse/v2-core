// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWCFX is IERC20Metadata {
    function deposit() external payable;
    function withdraw(uint256 value) external;
}
