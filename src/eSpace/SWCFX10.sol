// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
// import { ContextUpgradeable } from "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";
import { WCFX10Upgradeable } from "./WCFX10Upgradeable.sol";

contract SWCFX10 is OwnableUpgradeable, WCFX10Upgradeable {
    uint256 constant RATIO_BASE = 10000;
    uint256 public POS_RATIO;

    address public coreBridge; // core bridge mirror address

    uint256 public totalInPoS;
    uint256 public totalRedeemed; // total redeemed amount from core space
    
    function initialize(string memory _name, string memory _symbol) public initializer override {
        super.initialize(_name, _symbol);
        __Ownable_init();
        POS_RATIO = 5000;
    }

    modifier onlyBridge() {
        require(msg.sender == coreBridge, "Only bridge is allowed");
        _;
    }

    /**
     * @dev called by core bridge to cross CFX back
     */
    function handleRedeem() public onlyBridge payable {
        totalRedeemed -= msg.value;
        totalInPoS -= msg.value;
        _burn(address(this), msg.value);
    }

    function setCoreBridge(address _bridge) public onlyOwner {
        coreBridge = _bridge;
    }

    function setPoSRatio(uint256 _ratio) public onlyOwner {
        POS_RATIO = _ratio;
    }

    function _transferToBridge(uint256 _amount) internal {
        uint256 _balance = address(this).balance;
        require(_amount <= _balance, "not enough balance");
        address payable receiver = payable(coreBridge);
        receiver.transfer(_amount);
    }

    /**
     * @dev calculate the amount should be locked in or unlock from PoS
     */
    function _calPoSAmount(uint256 _amount) internal view returns (uint256) {
        return _amount * POS_RATIO / RATIO_BASE;
    }

    function _deposit(address to, uint256 value) internal override {
        uint256 amount = _calPoSAmount(value);
        _transferToBridge(amount);
        totalInPoS += amount;
        super._deposit(to, value);
    }

    function _withdraw(address from, address to, uint256 value) internal override {
        require(value > 0, "withdraw value must be greater than 0");
        uint256 _balance = address(this).balance;
        if (_balance >= value) {
            super._withdraw(from, to, value);
            totalRedeemed += _calPoSAmount(value);
        } else {
            revert("not enough balance, wait a while and try again");
        }
    }
}
