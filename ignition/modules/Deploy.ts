import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

/**
 * Deployment module for Campus Bounty Platform
 * Deploys all 4 contracts in correct order with dependencies
 */
const CampusBountyModule = buildModule("CampusBountyPlatform", (m) => {
  // 1. Deploy BountyToken with initial supply of 1 million tokens
  const initialSupply = 1_000_000n; // Will be multiplied by 10^18 in constructor
  const bountyToken = m.contract("BountyToken", [initialSupply]);

  // 2. Deploy ReputationNFT
  const reputationNFT = m.contract("ReputationNFT", []);

  // 3. Deploy BountyBoard with token and NFT addresses
  const bountyBoard = m.contract("BountyBoard", [bountyToken, reputationNFT]);

  // 4. Deploy EscrowManager with token address
  const escrowManager = m.contract("EscrowManager", [bountyToken]);

  // After deployment, we need to authorize BountyBoard as an issuer for ReputationNFT
  // This is done via a call after deployment
  m.call(reputationNFT, "addIssuer", [bountyBoard]);

  return {
    bountyToken,
    reputationNFT,
    bountyBoard,
    escrowManager,
  };
});

export default CampusBountyModule;
