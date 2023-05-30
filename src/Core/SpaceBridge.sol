// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { CrossSpaceCall } from "@confluxfans/contracts/InternalContracts/CrossSpaceCall.sol";
import { IPoSPool } from "../interfaces/IPoSPool.sol";

/**
 * @dev SpaceBridge is a PoS bridge contract for eSpace PoS pool contract. Can transfer CFX between Conflux eSpace and Core.
 */
contract SpaceBridge is Ownable {
    CrossSpaceCall internal constant CROSS_SPACE_CALL = CrossSpaceCall(0x0888000000000000000000000000000000000006);
    uint256 public constant CFX_PER_VOTE = 1000 ether;
    uint256 public constant RATIO_BASE = 1000_000_000;

    IPoSPool internal posPool;
    address public posPoolAddr;
    address public eSpacePoolAddr;
    
    function setPoSPool(address poolAddress) public onlyOwner {
        posPoolAddr = poolAddress;
        posPool = IPoSPool(poolAddress);
    }

    function setESpacePool(address eSpacePoolAddress) public onlyOwner {
        eSpacePoolAddr = eSpacePoolAddress;
    }

    function transferToEspacePool(uint256 amount) public onlyOwner {
        require(amount <= _balance(), "Not enough balance");
        CROSS_SPACE_CALL.transferEVM{value: amount}(_ePoolAddrB20());
    }

    function transferToEspacePool() public onlyOwner {
        uint256 _amount = _balance();
        CROSS_SPACE_CALL.transferEVM{value: _amount}(_ePoolAddrB20());
    }

    function transferFromEspace(uint256 amount) public onlyOwner {
        require(mappedBalance() >= amount, "Not enough balance");
        CROSS_SPACE_CALL.withdrawFromMapped(amount);
    }

    function transferFromEspace() public onlyOwner {
        uint256 _amount = mappedBalance();
        CROSS_SPACE_CALL.withdrawFromMapped(_amount);
    }

    function poolInterest() public view returns (uint256) {
        uint256 interest = posPool.userInterest(address(this));
        return interest;
    }

    function poolSummary() public view returns (IPoSPool.UserSummary memory) {
        IPoSPool.UserSummary memory userSummary = posPool.userSummary(address(this));
        return userSummary;
    }

    function mappedBalance() public view returns (uint256) {
        return CROSS_SPACE_CALL.mappedBalance(address(this));
    }

    function _balance() internal view returns (uint256) {
        return address(this).balance;
    }

    function _ePoolAddrB20() internal view returns (bytes20) {
        return bytes20(eSpacePoolAddr);
    }
}
