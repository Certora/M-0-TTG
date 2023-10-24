# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# dapp deps
update:; forge update

# coverage report
coverage :; forge coverage --report lcov && lcov --remove ./lcov.info -o ./lcov.info 'script/*' 'test/*' && genhtml lcov.info --branch-coverage --output-dir coverage

# Deployment helpers

deploy-local :; FOUNDRY_PROFILE=production forge script script/Deploy.s.sol --rpc-url localhost --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -v

deploy-sepolia :; FOUNDRY_PROFILE=production forge script script/Deploy.s.sol --rpc-url sepolia --private-key ${ETH_PK} --broadcast -vvv

deploy-qa-sepolia :; FOUNDRY_PROFILE=production forge script script/Deploy.s.sol --rpc-url sepolia --broadcast -v

# Run slither
slither :; FOUNDRY_PROFILE=production forge build --build-info --skip '*/test/**' --skip '*/script/**' --force && slither --compile-force-framework foundry --ignore-compile --sarif results.sarif --config-file slither.config.json .

build:
	@./build.sh -p production

tests:
	@./test.sh -p default

gas:
	@./test.sh -p production -g

sizes:
	@./build.sh -p production -s

clean:
	forge clean && rm -rf ./abi && rm -rf ./bytecode && rm -rf ./types
