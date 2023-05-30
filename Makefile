CHAIN = CFX_TEST

deployTreasury:
	forge script script/eSpace.s.sol:DeployTreasury --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deployPHX:
	forge script script/eSpace.s.sol:DeployPHX --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deployCCFX:
	forge script script/eSpace.s.sol:DeployCCFX --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deployProxyAdmin:
	forge script script/eSpace.s.sol:DeployProxyAdmin --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deployLiquidityPool:
	forge script script/eSpace.s.sol:DeployLiquidityPool --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deploySWCFX:
	forge script script/eSpace.s.sol:DeploySWCFX --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300

deploySWCFXProxy:
	forge script script/eSpace.s.sol:DeploySWCFXProxy --rpc-url ${CHAIN} --broadcast --legacy --gas-estimate-multiplier 300