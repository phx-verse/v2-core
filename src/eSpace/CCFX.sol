// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC20PresetMinterPauserUpgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { RedeemQueue } from "../utils/RedeemQueue.sol";
import { IFarmingPool } from "../interfaces/IFarmingPool.sol";

contract CCFX is ERC20PresetMinterPauserUpgradeable {
    using RedeemQueue for RedeemQueue.Queue;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ======================== Events =========================
    event Deposit(address indexed user, uint256 amount, uint256 share);
    event Redeem(address indexed user, uint256 share, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    bytes32 constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
    uint256 constant RATIO_BASE = 1000_000_000;

    IFarmingPool public farmingPool; // farming pool address
    address public coreBridge; // core bridge mirror address
    
    uint256 public totalAssets; // total assets of CFX in this pool
    uint256 public totalRedeemedAssets; // total redeemed assets, which is the assets that is need fullfilled from CoreBridge
    
    mapping(address => uint256) public userRedeemedAssets;
    mapping(address => uint256) public userWithdrawableAssets;

    EnumerableSet.AddressSet private _stakers;
    RedeemQueue.Queue private _redeemQueue;

    function initialize() public initializer {
        super.initialize("PoS Compound CFX", "cCFX");
        _setupRole(TOKEN_ADMIN_ROLE, _msgSender());
    }

    function deposit() public payable {
        require(msg.value > 0, "deposit amount must be greater than 0");
        uint256 amount = msg.value;

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / totalAssets; // assets to shares
        }

        _mint(msg.sender, shares);
        totalAssets += amount;

        _transferToBridge(amount);

        emit Deposit(msg.sender, amount, shares);
    }

    function redeem(uint256 shares) public {
        require(shares > 0, "redeem amount must be greater than 0");

        uint256 amount = (shares * totalAssets) / totalSupply(); // shares to assets
        _burn(msg.sender, shares);
        totalAssets -= amount;

        _redeemQueue.enqueue(RedeemQueue.Node({amount: amount, user: msg.sender}));
        userRedeemedAssets[msg.sender] += amount;

        totalRedeemedAssets += amount;

        emit Redeem(msg.sender, shares, amount);
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "withdraw amount must be greater than 0");
        require(amount <= userWithdrawableAssets[msg.sender], "not enough redeemable amount");
        require(amount <= address(this).balance, "not enough balance");
        
        address payable receiver = payable(msg.sender);
        receiver.transfer(amount);
        userWithdrawableAssets[msg.sender] -= amount;

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev return CFX / cCFX ratio, multiplied by RATIO_BASE
     */
    function cfxRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 1;
        return totalAssets * RATIO_BASE / totalSupply();
    }

    function stakerNumber() public view returns (uint256) {
        return _stakers.length();
    }

    function stakerAddress(uint256 i) public view returns (address) {
        return _stakers.at(i);
    }

    function redeemLen() public view returns (uint256) {
        return _redeemQueue.end - _redeemQueue.start;
    }

    function firstRedeemAmount() public view returns (uint256) {
        if (_redeemQueue.end == _redeemQueue.start) return 0;
        return _redeemQueue.items[_redeemQueue.start].amount;
    }

    function redeemQueue() public view returns (RedeemQueue.Node[] memory) {
        RedeemQueue.Node[] memory nodes = new RedeemQueue.Node[](_redeemQueue.end - _redeemQueue.start);
        for (uint256 i = _redeemQueue.start; i < _redeemQueue.end; i++) {
            nodes[i - _redeemQueue.start] = _redeemQueue.items[i];
        }
        return nodes;
    }

    /////////// functions for core bridge to call ///////////
    modifier onlyBridge() {
        require(msg.sender == coreBridge, "Only bridge is allowed");
        _;
    }
    
    function handleRedeem() public payable onlyBridge {
        uint256 _value = msg.value;
        RedeemQueue.Node memory node = _redeemQueue.dequeue();
        require(node.amount == _value, "redeem amount not match");
        require(_value <= totalRedeemedAssets, "abnormal value");
        totalRedeemedAssets -= _value;

        userWithdrawableAssets[node.user] += _value;
        userRedeemedAssets[node.user] -= _value;
    }

    function addAssets(uint256 delta) public onlyBridge {
        totalAssets += delta;
    }

    /////////// admin functions ///////////
    function setCoreBridge(address bridge) public onlyRole(TOKEN_ADMIN_ROLE) {
        coreBridge = bridge;
    }

    function setFarmingPool(address pool) public onlyRole(TOKEN_ADMIN_ROLE) {
        farmingPool = IFarmingPool(pool);
    }

    function _transferToBridge() private {
        uint256 _amount = address(this).balance;
        address payable receiver = payable(coreBridge);
        receiver.transfer(_amount);
    }

    function _transferToBridge(uint256 amount) private {
        uint256 _balance = address(this).balance;
        require(amount <= _balance, "not enough balance");
        address payable receiver = payable(coreBridge);
        receiver.transfer(amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (amount > 0) {
            farmingPool.updateYield(from);
            farmingPool.updateYield(to);
            
            _stakers.add(to);
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        if (balanceOf(from) == 0) {
            _stakers.remove(from);
        }
    }
}
