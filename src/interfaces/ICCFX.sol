// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICCFX is IERC20Metadata {
    /**
     * @dev Deposit CFX into this contract and get cCFX
     */
    function deposit() external;

    /**
     * @dev Withdraw CFX from this contract by burning cCFX, need approve first
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Total CFX assets in this contract
     */
    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}
