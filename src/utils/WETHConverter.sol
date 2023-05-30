// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface WETH9Like {
    function withdraw(uint256) external;
    function deposit() external payable;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface WETH10Like {
    function depositTo(address) external payable;
    function withdrawFrom(address, address, uint256) external;
}

contract WethConverter {
    WETH9Like immutable private weth9;
    WETH10Like immutable private weth10;

    constructor(address w9, address w10) {
        weth9 = WETH9Like(w9);
        weth10 = WETH10Like(w10);
    }   
    
    receive() external payable {}

    function weth9ToWeth10(address account, uint256 value) external payable {
        weth9.transferFrom(account, address(this), value);
        weth9.withdraw(value);
        weth10.depositTo{value: value + msg.value}(account);
    }

    function weth10ToWeth9(address account, uint256 value) external payable {
        weth10.withdrawFrom(account, address(this), value);
        uint256 combined = value + msg.value;
        weth9.deposit{value: combined}();
        weth9.transfer(account, combined);
    }
}