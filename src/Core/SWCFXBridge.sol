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

    function handleRedeem() public onlyOwner {
        IPoSPool.UserSummary memory userSummary = poolSummary();
        if (userSummary.unlocked > 0) {
            posPool.withdrawStake(userSummary.unlocked);
        }

        uint256 _totalRedeemed = eSpaceTotalRedeemed();
        if (_totalRedeemed == 0) return;
        uint256 _balanceBeforeHandle = _balance();
        if (_balanceBeforeHandle >= _totalRedeemed) {
            eSpaceHandleRedeem(_totalRedeemed);
            return;
        } else if (_balanceBeforeHandle > 0) {
            eSpaceHandleRedeem(_balanceBeforeHandle);
        }

        uint256 _left = _totalRedeemed - _balanceBeforeHandle;
        uint256 unlocking = userSummary.votes - userSummary.available - userSummary.unlocked;
        if (unlocking * CFX_PER_VOTE >= _left) return;

        uint256 _need = (_left - unlocking * CFX_PER_VOTE) / CFX_PER_VOTE;
        if ((_need + unlocking) * CFX_PER_VOTE < _left) _need += 1;
        if (_need > userSummary.locked) _need = userSummary.locked;

        posPool.decreaseStake(uint64(_need));
    }

    /////////////// cross space call methods ///////////////
    function eSpaceTotalRedeemed() public view returns (uint256) {
        bytes memory num = CROSS_SPACE_CALL.staticCallEVM(_ePoolAddrB20(), abi.encodeWithSignature("totalRedeemed()"));
        return abi.decode(num, (uint256));
    }

    function eSpaceHandleRedeem(uint256 _amount) public onlyOwner {
        CROSS_SPACE_CALL.callEVM{value: _amount}(_ePoolAddrB20(), abi.encodeWithSignature("handleRedeem()"));
    }

    function eSpaceSendInterest(uint256 _amount) public onlyOwner {
        CROSS_SPACE_CALL.callEVM{value: _amount}(_ePoolAddrB20(), abi.encodeWithSignature("receiveInterest()"));
    }

    // fallback() external payable {}

    receive() external payable {}
}