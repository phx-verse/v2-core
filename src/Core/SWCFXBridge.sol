// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IPoSPool } from "../interfaces/IPoSPool.sol";
import { SpaceBridge } from "./SpaceBridge.sol";

contract SWCFXBridge is Ownable, Initializable, SpaceBridge {
    function initialize() public initializer {}

    function stakeVotes() public onlyOwner {
        uint256 _amount = _balance();
        if (_amount < CFX_PER_VOTE) return;

        uint256 _vote = _amount / CFX_PER_VOTE;
        posPool.increaseStake(uint64(_vote));
    }

    function claimInterest() public onlyOwner {
        uint256 interest = poolInterest();
        if (interest == 0) return;
        posPool.claimInterest(interest);
        eSpaceSendInterest(interest);
    }

    // @param
    // redeemed: the amount need redeemed
    function handleRedeem(uint256 redeemed) public onlyOwner {
        require(redeemed > 0, "no need redeem");
        IPoSPool.UserSummary memory userSummary = poolSummary();
        if (userSummary.unlocked > 0) {
            posPool.withdrawStake(userSummary.unlocked);
            userSummary.unlocked = 0;
        }

        uint256 _balanceBeforeHandle = _balance();
        if (_balanceBeforeHandle >= redeemed) {
            eSpaceHandleRedeem(redeemed);
            return;
        } else if (_balanceBeforeHandle > 0) {
            eSpaceHandleRedeem(_balanceBeforeHandle);
        }

        uint256 _left = redeemed - _balanceBeforeHandle;
        uint256 unlocking = userSummary.votes - userSummary.available - userSummary.unlocked;
        if (unlocking * CFX_PER_VOTE >= _left) return;

        uint256 _need = (_left - unlocking * CFX_PER_VOTE) / CFX_PER_VOTE;
        if ((_need + unlocking) * CFX_PER_VOTE < _left) _need += 1;
        if (_need > userSummary.locked) _need = userSummary.locked;
        if (_need == 0) return; // locked is 0

        posPool.decreaseStake(uint64(_need));
    }

    /////////////// cross space call methods ///////////////

    function eSpaceHandleRedeem(uint256 _amount) internal {
        CROSS_SPACE_CALL.callEVM{value: _amount}(_ePoolAddrB20(), abi.encodeWithSignature("handleRedeem()"));
    }

    function eSpaceSendInterest(uint256 _amount) internal {
        CROSS_SPACE_CALL.callEVM{value: _amount}(_ePoolAddrB20(), abi.encodeWithSignature("receiveInterest()"));
    }

    function eSpaceTotalSupply() public returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.callEVM(_ePoolAddrB20(), abi.encodeWithSignature("totalSupply()"));
        return abi.decode(num, (uint256));
    }

    function eSpaceTotalInPoS() public returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.callEVM(_ePoolAddrB20(), abi.encodeWithSignature("totalInPoS()"));
        return abi.decode(num, (uint256));
    }

    function eSpaceRatioBase() public returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.callEVM(_ePoolAddrB20(), abi.encodeWithSignature("RATIO_BASE()"));
        return abi.decode(num, (uint256));
    }

    function eSpacePoSRatio() public returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.callEVM(_ePoolAddrB20(), abi.encodeWithSignature("POS_RATIO()"));
        return abi.decode(num, (uint256));
    }

    // fallback() external payable {}

    receive() external payable {}
}