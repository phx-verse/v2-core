// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { ERC20FlashMint } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { IWETH10 } from "../interfaces/IWETH10.sol";
import { ITransferReceiver } from "../interfaces/ITransferReceiver.sol";
import { IApprovalReceiver } from "../interfaces/IApprovalReceiver.sol";

/**
 * @dev Support deposit and withdraw CFX
 *
 * Ref: WETH9 https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
 *      WETH10 https://github.com/WETH10/WETH10
 *      meth-weth https://github.com/Philogy/meth-weth
 */
contract WCFX10 is ERC20PresetMinterPauser, IWETH10, ERC20FlashMint, ERC20Permit("WCFX10") {

    event Deposit(address indexed to, uint256 amount);

    event Withdrawal(address indexed from, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {}

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20PresetMinterPauser) {
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