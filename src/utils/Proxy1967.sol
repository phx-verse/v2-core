// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Proxy1967 is ERC1967Proxy, Ownable  {
    // initialize() - "0x8129fc1c"
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}

    function implementation() public view returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);
    }
}