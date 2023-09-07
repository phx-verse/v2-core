// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { ERC20FlashMintUpgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import { ERC20PresetMinterPauserUpgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import { IWETH10Upgradeable } from "../interfaces/IWETH10Upgradeable.sol";
import { ITransferReceiver } from "../interfaces/ITransferReceiver.sol";
import { IApprovalReceiver } from "../interfaces/IApprovalReceiver.sol";

/**
 * @dev Support deposit and withdraw CFX
 *
 * Ref: WETH9 https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
 *      WETH10 https://github.com/WETH10/WETH10
 *      meth-weth https://github.com/Philogy/meth-weth
 */
contract WCFX10Upgradeable is IWETH10Upgradeable, ERC20PresetMinterPauserUpgradeable, ERC20FlashMintUpgradeable, ERC20PermitUpgradeable {

    event Deposit(address indexed to, uint256 amount);

    event Withdrawal(address indexed from, uint256 amount);

    function initialize(string memory _name, string memory _symbol) public initializer override virtual {
        __ERC20PresetMinterPauser_init_unchained(_name, _symbol);
        __ERC20FlashMint_init_unchained();
        __ERC20Permit_init_unchained(_name);
    }

    receive() external payable {
        _deposit(_msgSender(), msg.value);
    }

    function deposit() external payable override {
        _deposit(_msgSender(), msg.value);
    }

    function depositTo(address account) external payable override {
        _deposit(account, msg.value);
    }

    function depositFor(address account) external payable override {
        _deposit(account, msg.value);
    }

    function withdraw(uint256 value) external override {
        _withdraw(_msgSender(), _msgSender(), value);
    }

    function withdrawTo(address payable to, uint256 value) external override {
        _withdraw(_msgSender(), to, value);
    }

    function withdrawFrom(address from, address payable to, uint256 amount) external override {
        _spendAllowance(from, _msgSender(), amount);
        _withdraw(from, to, amount);
    }

    function depositToAndCall(address to, bytes calldata data) external payable override returns (bool success) {
        _deposit(to, msg.value);

        return ITransferReceiver(to).onTokenTransfer(_msgSender(), msg.value, data);
    }

    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        approve(spender, value);

        return IApprovalReceiver(spender).onTokenApproval(_msgSender(), value, data);
    }

    function transferAndCall(address to, uint256 value, bytes calldata data) external override returns (bool) {
        transfer(to, value);
        return ITransferReceiver(to).onTokenTransfer(_msgSender(), value, data);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PresetMinterPauserUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _deposit(address to, uint256 value) internal virtual {
        _mint(to, value);
        emit Deposit(to, value);
    }

    function _withdraw(address from, address to, uint256 value) internal virtual {
        _burn(from, value);

        (bool success,) = to.call{value: value}("");
        require(success, "sWCFX: CFX transfer failed");

        emit Withdrawal(from, value);
    }

}