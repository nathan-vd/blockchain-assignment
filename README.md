# Blockchain Assignment

## Overview

This project implements a finance-focused credit data sharing platform where:

- Users register hashed identities and can grant/revoke consent for specific data attributes.
- Requesters submit access requests and must hold valid consent before reading data.
- A submitter role updates verified credit scores.
- All interactions emit audit logs and reward consent grants with tokens.

## Running the demo

```bash
cd blockchain-assignment
npm install
npx hardhat node          # start in a separate terminal
npx hardhat compile
npx hardhat run scripts/five-user-demo.ts --network localhost
```

The demo deploys the `DataSharing` stack and executes the full consent lifecycle for five user/requester pairs, printing gas usage and timing for each transaction.

## Running the tests

```bash
cd blockchain-assignment
npx hardhat test --gas-stats
```

This command compiles the contracts and runs all Solidity-based unit tests (IdentityManager, ConsentManager, AccessToken, AuditLog, and DataSharing). The `--gas-stats` flag prints gas usage per function.
