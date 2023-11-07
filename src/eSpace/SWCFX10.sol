// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { WCFX10Upgradeable } from "./WCFX10Upgradeable.sol";

/*
    todo
    1. APR
*/ 
contract SWCFX10 is OwnableUpgradeable, WCFX10Upgradeable {
    uint256 constant RATIO_BASE = 1000_000;
    uint256 public POS_RATIO;

    address public coreBridge; // core bridge mirror address

    uint256 public totalInPoS;
    uint256 public totalInterest;

     // Sum of (reward * 1e18 / total supply)
    uint256 public rewardPerToken;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    
    function initialize(string memory _name, string memory _symbol) public initializer override {
        super.initialize(_name, _symbol);
        __Ownable_init();
        POS_RATIO = 300_000; // 30 percent
    }

    modifier onlyBridge() {
        require(msg.sender == coreBridge, "Only bridge is allowed");
        _;
    }

    /**
     * @dev called by core bridge to cross CFX back
     */
    function handleRedeem() public onlyBridge payable {
        totalInPoS -= msg.value;
    }

    function receiveInterest() public onlyBridge payable {
        totalInterest += msg.value;

        rewardPerToken += msg.value * 1e18 / totalSupply();
    }

    function setCoreBridge(address _bridge) public onlyOwner {
        coreBridge = _bridge;
    }

    function setPoSRatio(uint256 _ratio) public onlyOwner {
        POS_RATIO = _ratio;
    }

    function claimReward() public {
        _updateUserReward(msg.sender);
        address payable receiver = payable(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        receiver.transfer(reward);
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

    function _updateUserReward(address user) internal {
        if (user == address(0x0) || balanceOf(user) == 0) return;
        rewards[user] += (rewardPerToken - userRewardPerTokenPaid[user]) * balanceOf(user) / 1e18;
        userRewardPerTokenPaid[user] = rewardPerToken;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        _updateUserReward(from);
        _updateUserReward(to);
    }

    function _deposit(address to, uint256 value) internal override {
        // when total supply surpass a value, specific proportion of value will transfer to bridge address
        if (totalSupply() > 1000_000 ether) { 
            uint256 _amount = _calPoSAmount(value);
            totalInPoS += _amount;
            _transferToBridge(_amount);
        }
        super._deposit(to, value);
    }

    function _withdraw(address from, address to, uint256 value) internal override {
        require(value > 0, "withdraw value must be greater than 0");
        uint256 _balance = address(this).balance;
        if (_balance >= value) {
            super._withdraw(from, to, value);
        } else {
            revert("not enough balance, wait a while and try again");
        }
    }
}
