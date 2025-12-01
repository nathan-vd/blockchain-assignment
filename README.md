# Decentralized Digital Identity & Data Sharing (Skeleton)

This repository bootstraps the project described in `../prompt.txt`: a finance-focused decentralized identity and data sharing platform where users control consent, every access attempt is logged, and incentives are provided via access tokens.

## Repository Layout
- `contracts/`
  - `DigitalIdentity.sol`, `ConsentManager.sol`, `DataAccessRegistry.sol`, `AccessToken.sol` – **abstract** placeholders exposing only function signatures so you can implement the business logic yourself
- `scripts/deploy.ts` – placeholder Hardhat deployment script (will only work once the contracts have implementations)
- `docs/requirements.md` – distilled research, roles, and functional requirements
- `docs/design.md` – data model table, consent workflow, and component-level architecture sketch
- `hardhat.config.ts` – Hardhat + Viem toolbox configuration (Solidity 0.8.30)
- `tsconfig.json` – TypeScript settings for scripts/tests

## Getting Started
1. Install dependencies
   ```bash
   npm install
   ```
2. Compile contracts
   ```bash
   npx hardhat compile
   ```
3. Implement the contract logic you need (current Solidity files contain only function titles)
4. Start a local node and deploy (after implementations are ready)
   ```bash
   npx hardhat node
   # new terminal
   npx hardhat run scripts/deploy.ts --network localhost
   ```

## Next Steps
- Flesh out ConsentManager and DataAccessRegistry with full business logic (token rewards, admin controls, verifier attestations)
- Add tests (none are included yet) to cover consent lifecycle, audit logging, and integration workflows
- Capture gas metrics and document them per assignment requirements
- (Optional) Scaffold a frontend that connects via Viem to manage identities, consent, and audit logs

Refer to the `docs/` folder for the planning artifacts that map directly to the assignment brief.
