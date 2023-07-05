# PHX V2 Conflux Liquid Staking Protocol

This repository contains the core smart contracts for the PHX PoS Liquid V2 Protocol.

## Local deployment

This project is using [Foundry](https://book.getfoundry.sh/) and [Hardhat](https://hardhat.org/) for local development and deployment.
First ensure foundry is installed on your local machine. Then clone the repo and install dependencies:

```bash
git clone https://github.com/phx-verse/v2-core.git
cd v2-core && npm install
```

Compile the contracts with command:

```bash
forge build # or npx hardhat compile
```

## Licensing

The primary license for PHX PoS Pool V2 Core is the Business Source License 1.1 (BUSL-1.1), see [LICENSE](./LICENSE).
