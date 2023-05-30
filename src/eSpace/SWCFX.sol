// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";
import { WCFX10Upgradeable } from "./WCFX10Upgradeable.sol";
import { ILiquidityPool } from "../interfaces/ILiquidityPool.sol";

contract SWCFX is ContextUpgradeable, OwnableUpgradeable, WCFX10Upgradeable {
    // user reward info
    struct RewardInfo {
        uint256 rewards;
        uint256 accRewardPerCfx;
    }

    uint256 constant RATIO_BASE = 10000;
    uint256 public POS_RATIO;
    uint256 public minimumBar;

    address public coreBridge; // core bridge mirror address
    ILiquidityPool public liquidityPool;

    uint256 public totalInPoS;
    uint256 public totalRedeemed; // total redeemed amount from core space
    uint256 public totalLend; // total lend amount from liquidity pool

    uint256 public accRewardPerCfx;
    uint256 public lastShotSupply; // last time supply when shot reward
    mapping(address => RewardInfo) public userRewardInfos;
    
    function initialize(string memory _name, string memory _symbol) public initializer override {
        super.initialize(_name, _symbol);
        __Ownable_init();
        POS_RATIO = 5000;
        minimumBar = 1000_000 ether;
    }

    modifier onlyBridge() {
        require(msg.sender == coreBridge, "Only bridge is allowed");
        _;
    }

    function receiveInterest() public onlyBridge payable {
        if (lastShotSupply == 0 || msg.value == 0) return;
        accRewardPerCfx += msg.value * 1e18 / lastShotSupply;
        lastShotSupply = totalSupply();
    }

    function receiveLend() public payable {
        totalLend += msg.value;
    }

    // TODO
    function APR() public view returns (uint256) {
        return 600;
    }

    function userReward() public view returns (uint256) {
        uint256 _reward = userRewardInfos[msg.sender].rewards;
        uint256 _sectionReward = balanceOf(msg.sender) * (accRewardPerCfx - userRewardInfos[msg.sender].accRewardPerCfx) / 1e18;
        return _reward + _sectionReward;
    }

    function claimReward() public {
        _updateUserRewards(msg.sender);
        uint256 _reward = userRewardInfos[msg.sender].rewards;
        (bool _success,) = msg.sender.call{value: _reward}("");
        userRewardInfos[msg.sender].rewards = 0;
    }

    /**
     * @dev called by core bridge to cross CFX back
     */
    function handleRedeem() public onlyBridge payable {
        totalRedeemed -= msg.value;
        totalInPoS -= msg.value;

        // pay back to liquidity pool
        if (totalLend == 0) return;

        if (msg.value >= totalLend) {
            liquidityPool.repayForSWCFX{value: totalLend}();
            _burn(address(this), totalLend);
            totalLend = 0;
        } else {
            liquidityPool.repayForSWCFX{value: msg.value}();
            _burn(address(this), msg.value);
            totalLend -= msg.value;
        }
    }

    function setCoreBridge(address _bridge) public onlyOwner {
        coreBridge = _bridge;
    }

    function setLiquidPool(address _pool) public onlyOwner {
        liquidityPool = ILiquidityPool(_pool);
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

    function _updateUserRewards(address _user) internal {
        uint256 _balance = balanceOf(_user);
        if (_balance == 0 || accRewardPerCfx == userRewardInfos[_user].accRewardPerCfx) return;
        
        uint256 _sectionReward = _balance * (accRewardPerCfx - userRewardInfos[_user].accRewardPerCfx) / 1e18;
        userRewardInfos[_user].rewards += _sectionReward;
        userRewardInfos[_user].accRewardPerCfx = accRewardPerCfx;
    }

    /**
     * @dev calculate the amount should be locked in or unlock from PoS
     */
    function _calPoSAmount(uint256 _amount) internal view returns (uint256) {
        return _amount * POS_RATIO / RATIO_BASE;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        _updateUserRewards(from);
        _updateUserRewards(to);
        super._beforeTokenTransfer(from, to, amount);
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
            if (liquidityPool.totalLiquidity() + _balance >= value) {
                uint256 _toLend = value - _balance;
                
                _transfer(from, address(this), _toLend);
                _approve(address(this), address(liquidityPool), _toLend);
                liquidityPool.lendBySWCFX(_toLend);
                
                totalRedeemed += _calPoSAmount(value);
                // burn payable part
                _burn(from, _balance);
                (bool success,) = to.call{value: value}("");
                require(success, "sWCFX: CFX transfer failed");
                emit Withdrawal(from, value);
            } else {
                revert("not enough balance, wait a while and try again");
            }
        }
    }
    
}
