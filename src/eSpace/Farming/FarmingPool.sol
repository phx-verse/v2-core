// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev The cCFX farming pool contract
 */
contract FarmingPool is AccessControl, Initializable {
    bytes32 constant PHX_ADMIN_ROLE = keccak256("PHX_ADMIN_ROLE");
    
    IERC20 public PHX;
    IERC20 public cCFX;

    struct UserInfo {
        uint256 rewardPerShare; // Accumulated reward per share.
        uint256 pendingReward; // Reward not claimed
    }

    struct PoolInfo {
        uint256 duration;
        uint256 finishAt;
        uint256 rewardRate;
        uint256 lastRewardTime;
        uint256 accRewardPerShare;
    }

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfos;

    function initialize() public initializer {
        _setupRole(PHX_ADMIN_ROLE, _msgSender());
    }

    // TODO: check security of this function
    function updateYield(address account) public {
        poolInfo.accRewardPerShare = _rewardPerToken();
        poolInfo.lastRewardTime = _lastTimeRewardApplicable();

        if (account != address(0)) {
            userInfos[account].pendingReward = userReward(account);
            userInfos[account].rewardPerShare = poolInfo.accRewardPerShare;
        }
    }

    function userReward(address account) public view returns (uint256) {
        uint256 realtimeReward = (cCFX.balanceOf(account) * (_rewardPerToken() - userInfos[account].rewardPerShare)) / 1e18;
        return realtimeReward + userInfos[account].pendingReward;
    }

    function claimReward() public {
        updateYield(msg.sender);
        uint256 reward = userInfos[msg.sender].pendingReward;
        if (reward > 0) {
            userInfos[msg.sender].pendingReward = 0;
            PHX.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint256 duration) public onlyRole(PHX_ADMIN_ROLE) {
        require(poolInfo.finishAt < block.timestamp, "reward duration not finished");
        poolInfo.duration = duration;
    }

    function setRewardAmount(uint256 amount) public onlyRole(PHX_ADMIN_ROLE) {
        if (block.timestamp >= poolInfo.finishAt) {
            poolInfo.rewardRate = amount / poolInfo.duration;
        } else {
            uint256 remainingRewards = (poolInfo.finishAt - block.timestamp) * poolInfo.rewardRate;
            poolInfo.rewardRate = (amount + remainingRewards) / poolInfo.duration;
        }

        require(poolInfo.rewardRate > 0, "reward rate = 0");
        require(
            poolInfo.rewardRate * poolInfo.duration <= PHX.balanceOf(address(this)),
            "reward amount > balance"
        );

        poolInfo.finishAt = block.timestamp + poolInfo.duration;
        poolInfo.lastRewardTime = block.timestamp;
    }

    function setCCFX(address cCFXAddr) public onlyRole(PHX_ADMIN_ROLE) {
        cCFX = IERC20(cCFXAddr);
    }

    function setPHX(address phxAddr) public onlyRole(PHX_ADMIN_ROLE) {
        PHX = IERC20(phxAddr);
    }

    /**
     * @dev total supply of cCFX
     */
    function _totalSupply() internal view returns (uint256) {
        return cCFX.totalSupply();
    }

    function _rewardPerToken() internal view returns (uint256) {
        if (_totalSupply() == 0) return poolInfo.accRewardPerShare;
        uint256 realtimeReward = (poolInfo.rewardRate * (_lastTimeRewardApplicable() - poolInfo.lastRewardTime) * 1e18) / _totalSupply();
        return poolInfo.accRewardPerShare + realtimeReward;
    }

    function _lastTimeRewardApplicable() internal view returns (uint256) {
        return _min(poolInfo.finishAt, block.timestamp);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
