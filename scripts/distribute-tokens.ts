/**
 * Script to distribute Campus Bounty Tokens to test accounts
 * Run with: npx hardhat run scripts/distribute-tokens.ts --network localhost
 */

import { createPublicClient, createWalletClient, http, parseEther } from "viem";
import { hardhat } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// Contract address (update if redeployed)
const BOUNTY_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

// Test accounts to receive tokens (excluding deployer at index 0)
const TEST_ACCOUNTS = [
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // Account #1
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // Account #2
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906", // Account #3
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", // Account #4
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc", // Account #5
];

// Amount to distribute to each account
const AMOUNT_PER_ACCOUNT = "10000"; // 10,000 CBT tokens

async function main() {
  console.log("🚀 Starting token distribution...\n");

  // Deployer account (has all tokens)
  const deployerPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const deployerAccount = privateKeyToAccount(deployerPrivateKey as `0x${string}`);

  // Create clients
  const publicClient = createPublicClient({
    chain: hardhat,
    transport: http("http://127.0.0.1:8545"),
  });

  const walletClient = createWalletClient({
    account: deployerAccount,
    chain: hardhat,
    transport: http("http://127.0.0.1:8545"),
  });

  console.log(`Deployer: ${deployerAccount.address}`);
  console.log(`Token Contract: ${BOUNTY_TOKEN_ADDRESS}`);
  console.log(`Amount per account: ${AMOUNT_PER_ACCOUNT} CBT\n`);

  // BountyToken ABI (minimal - just what we need)
  const tokenABI = [
    {
      inputs: [
        { name: "recipient", type: "address" },
        { name: "amount", type: "uint256" },
      ],
      name: "transfer",
      outputs: [{ name: "", type: "bool" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [{ name: "account", type: "address" }],
      name: "balanceOf",
      outputs: [{ name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function",
    },
  ] as const;

  // Distribute tokens
  for (const recipient of TEST_ACCOUNTS) {
    try {
      console.log(`Transferring to ${recipient}...`);

      const hash = await walletClient.writeContract({
        address: BOUNTY_TOKEN_ADDRESS as `0x${string}`,
        abi: tokenABI,
        functionName: "transfer",
        args: [recipient as `0x${string}`, parseEther(AMOUNT_PER_ACCOUNT)],
      });

      console.log(`  Transaction: ${hash}`);

      // Wait for transaction
      await publicClient.waitForTransactionReceipt({ hash });

      // Check balance
      const balance = await publicClient.readContract({
        address: BOUNTY_TOKEN_ADDRESS as `0x${string}`,
        abi: tokenABI,
        functionName: "balanceOf",
        args: [recipient as `0x${string}`],
      });

      console.log(`  ✅ Balance: ${Number(balance) / 1e18} CBT\n`);
    } catch (error) {
      console.error(`  ❌ Error: ${error}\n`);
    }
  }

  console.log("✅ Token distribution complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
