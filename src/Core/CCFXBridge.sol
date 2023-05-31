// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IPoSPool } from "../interfaces/IPoSPool.sol";
import { IPoSOracle } from "../interfaces/IPoSOracle.sol";
import { SpaceBridge } from "./SpaceBridge.sol";

contract CCFXBridge is Ownable, Initializable, SpaceBridge {
    IPoSOracle private posOracle;

    uint256 public aprPeriodCount;
    uint256 public poolShareRatio;
    uint256 public poolAccInterest; // accumulated pool handling fee

    function initialize() public initializer {
        aprPeriodCount = 48; // 2 days
        poolShareRatio = 100_000_000;
    }

    function setPoSOracle(address addr) public onlyOwner {
        posOracle = IPoSOracle(addr);
    }

    function setPoolShareRatio(uint256 ratio) public onlyOwner {
        poolShareRatio = ratio;
    }

    function stakeAbleBalance() public view returns (uint256) {
        uint256 balance = _balance();
        if (balance <= poolAccInterest) return 0;
        balance -= poolAccInterest;
        uint256 _needRedeem = eSpacePoolTotalRedeemed();
        if (balance <= _needRedeem) return 0;
        balance -= _needRedeem;
        return balance;
    }

    // average hour APR in latest 'aprPeriodCount' period
    function poolAPR() public view returns (uint256) {
        uint256 posEpoch = posOracle.posEpochHeight();
        uint256 totalVotes;
        uint256 totalReward;

        for (uint256 i = 1; i <= aprPeriodCount; i++) {
            uint256 epoch = posEpoch - i;
            uint256 reward = posOracle.getUserPoSReward(epoch, posPoolAddr);
            if (reward == 0) continue;

            uint256 votes = posOracle.getUserVotes(epoch, posPoolAddr);
            totalVotes += votes;
            totalReward += reward;
        }

        uint256 apr = (totalReward * RATIO_BASE) / (totalVotes * CFX_PER_VOTE);
        return apr;
    }

    function claimInterest() public onlyOwner {
        uint256 interest = poolInterest();
        if (interest == 0) return;

        posPool.claimInterest(interest);
        
        uint256 poolShare = (interest * poolShareRatio) / RATIO_BASE;
        poolAccInterest += poolShare;
        eSpaceAddAssets(interest - poolShare);
    }

    function stakeVotes() public onlyOwner {
        uint256 _amount = _balance();

        uint256 _needRedeem = eSpacePoolTotalRedeemed();
        if (_amount < _needRedeem) return;
        _amount -= _needRedeem;

        // leave pool handling fee unstake as a liquidity pool for quick redeem
        if (_amount < poolAccInterest) return;
        _amount -= poolAccInterest;

        if (_amount < CFX_PER_VOTE) return;

        uint256 _vote = _amount / CFX_PER_VOTE;
        posPool.increaseStake{value: _vote * CFX_PER_VOTE}(uint64(_vote));
    }

    function handleRedeem() public onlyOwner {
        // withdraw unlocked votes
        IPoSPool.UserSummary memory userSummary = poolSummary();
        if (userSummary.unlocked > 0) {
            posPool.withdrawStake(userSummary.unlocked);
        }

        // Use current balance handle redeem request
        uint256 rL = eSpaceRedeemLen();
        if (rL == 0) return;
        for (uint256 i = 0; i < rL; i++) {
            bool handled = handleFirstRedeem();
            if (!handled) break;
        }

        if (userSummary.locked == 0) return;

        uint256 totalRedeemed = eSpacePoolTotalRedeemed();
        if (totalRedeemed == 0) return;

        // use total redeemed amount minus current unlocking votes, calculate need unstake votes
        uint256 unlocking = userSummary.votes - userSummary.available - userSummary.unlocked;
        if (unlocking * CFX_PER_VOTE + _balance() >= totalRedeemed) return;

        uint256 needUnstake = (totalRedeemed - unlocking * CFX_PER_VOTE) / CFX_PER_VOTE;
        if ((needUnstake + unlocking) * CFX_PER_VOTE < totalRedeemed) needUnstake += 1;
        if (needUnstake > userSummary.locked) needUnstake = userSummary.locked;

        posPool.decreaseStake(uint64(needUnstake));
    }

    function handleFirstRedeem() public onlyOwner returns (bool) {
        uint256 _amount = eSpaceFirstRedeemAmount();
        if (_balance() < _amount) return false;
        eSpaceHandleRedeem(_amount);
        return true;
    }

    /////////////// cross space call methods ///////////////

    function eSpaceAddAssets(uint256 amount) public onlyOwner {
        CROSS_SPACE_CALL.callEVM(_ePoolAddrB20(), abi.encodeWithSignature("addAssets(uint256)", amount));
    }

    function eSpaceHandleRedeem(uint256 amount) public onlyOwner {
        CROSS_SPACE_CALL.callEVM{value: amount}(_ePoolAddrB20(), abi.encodeWithSignature("handleRedeem()"));
    }

    function eSpaceRedeemLen() public view returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.staticCallEVM(_ePoolAddrB20(), abi.encodeWithSignature("redeemLen()"));
        return abi.decode(num, (uint256));
    }

    function eSpaceFirstRedeemAmount() public view returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.staticCallEVM(_ePoolAddrB20(), abi.encodeWithSignature("firstRedeemAmount()"));
        return abi.decode(num, (uint256));
    }

    function eSpacePoolTotalRedeemed() public view returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.staticCallEVM(_ePoolAddrB20(), abi.encodeWithSignature("totalRedeemedAssets()"));
        return abi.decode(num, (uint256));
    }

    // fallback() external payable {}

    receive() external payable {}
}
