// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract PHX is ERC20PresetMinterPauser {
    constructor(address genesisHolder) ERC20PresetMinterPauser("PHX Governance Token", "PHX") {
        _mint(genesisHolder, 100_000_000 ether);
    }
}
