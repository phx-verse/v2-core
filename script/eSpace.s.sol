// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/eSpace/cCFX.sol";
import "../src/utils/Proxy1967.sol";
import "../src/eSpace/PHX.sol";
import "../src/eSpace/Farming/FarmingPool.sol";
import { ProxyAdmin } from "../src/utils/ProxyAdmin.sol";
import { LiquidityPool } from "../src/eSpace/LiquidityPool.sol";
import { WCFX10Upgradeable } from '../src/eSpace/WCFX10Upgradeable.sol';
import { TransparentUpgradeableProxy } from '../src/utils/TransparentProxy.sol';
import { PHXTreasury } from '../src/eSpace/DAO/Treasury.sol';

contract DeployTreasury is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new PHXTreasury();
        vm.stopBroadcast();
    }
}

contract DeployPHX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new PHX(vm.envAddress("GENESIS_HOLDER_ADDR"));

        vm.stopBroadcast();
    }
}

contract DeployFarmingPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        FarmingPool farmPoolImpl = new FarmingPool();
        Proxy1967 proxy = new Proxy1967(address(farmPoolImpl), "0x8129fc1c");
        FarmingPool farmingPool = FarmingPool(address(proxy));
        
        vm.stopBroadcast();
    }
}

contract SetFarmingPoolCCFX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        FarmingPool farmingPool = FarmingPool(vm.envAddress("FARMING_POOL_ADDR"));
        farmingPool.setCCFX(vm.envAddress("CCFX_ADDR")); 

        vm.stopBroadcast();
    }
}

contract DeployCCFX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CCFX ccfxImpl = new CCFX();

        Proxy1967 ccfxProxy = new Proxy1967(address(ccfxImpl), "0x8129fc1c");
        CCFX ccfx = CCFX(address(ccfxProxy));

        ccfx.setFarmingPool(vm.envAddress("FARMING_POOL_ADDR"));
        ccfx.setCoreBridge(vm.envAddress("CORE_BRIDGE_ADDR"));

        vm.stopBroadcast();
    }
}

contract DeployProxyAdmin is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new ProxyAdmin();

        vm.stopBroadcast();
    }
}

contract DeployLiquidityPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new LiquidityPool();

        vm.stopBroadcast();
    }
}

contract DeploySWCFX is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new WCFX10Upgradeable();
        
        vm.stopBroadcast();
    }
}

contract DeploySWCFXProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // WCFX10Upgradeable swcfx_impl = new WCFX10Upgradeable();
        
        new TransparentUpgradeableProxy(0x15Eb1067225c6a15adeaf040b1c5f872800c1517, vm.envAddress("E_PROXY_ADMIN"), "0x8129fc1c");

        vm.stopBroadcast();
    }
}
