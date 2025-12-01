import { network } from "hardhat";
import { toHex } from "viem";

// Defines the wallet client type used by Hardhat + Viem helper calls.
type WalletClient = Awaited<ReturnType<Awaited<ReturnType<typeof network.connect>>["viem"]["getWalletClients"]>>[number];

// Static hashed UUIDs assigned to user accounts for deterministic demos.
const USER_HASHES = [
  "0x7573657231000000000000000000000000000000000000000000000000000000",
  "0x7573657232000000000000000000000000000000000000000000000000000000",
  "0x7573657233000000000000000000000000000000000000000000000000000000",
  "0x7573657234000000000000000000000000000000000000000000000000000000",
  "0x7573657235000000000000000000000000000000000000000000000000000000",
] as const;

const REQUESTER_HASHES = [
  "0x7265713031000000000000000000000000000000000000000000000000000000",
  "0x7265713032000000000000000000000000000000000000000000000000000000",
  "0x7265713033000000000000000000000000000000000000000000000000000000",
  "0x7265713034000000000000000000000000000000000000000000000000000000",
  "0x7265713035000000000000000000000000000000000000000000000000000000",
] as const;

// Attribute combinations requested in each workflow (DataType enum values).
const ATTRIBUTE_SETS: readonly bigint[][] = [
  [1n, 3n],
  [2n, 0n],
  [0n, 3n],
  [1n, 2n],
  [2n, 3n],
];

// Consent durations (days) and representative credit scores per workflow.
const DURATIONS: readonly bigint[] = [45n, 30n, 60n, 20n, 15n];
const CREDIT_SCORES: readonly bigint[] = [720n, 680n, 705n, 690n, 710n];

async function main() {
  console.log("\n=== Five User Deployment & Workflow Demo ===\n");

  const connection = await network.connect();
  const { viem } = connection;
  const publicClient = await viem.getPublicClient();
  const wallets = await viem.getWalletClients();

  // Extract the dedicated owner, submitter, and additional participant accounts.
  const [owner, submitter, ...participants] = wallets;
  if (participants.length < 10) {
    throw new Error("Need 10 additional accounts for 5 user/requester pairs.");
  }

  const users: WalletClient[] = participants.slice(0, 5);
  const requesters: WalletClient[] = participants.slice(5, 10);

  // Deploy the integrated DataSharing system that wires all modules together.
  console.log("Deploying DataSharing with owner:", owner.account.address);
  const dataSharing = await viem.deployContract("DataSharing", [], {
    client: { wallet: owner },
  });
  console.log("DataSharing deployed at:", dataSharing.address);
  console.log("");

  const recordTx = async (label: string, sendTx: () => Promise<`0x${string}`>) => {
    const start = Date.now();
    const hash = await sendTx();
    const { gasUsed } = await publicClient.waitForTransactionReceipt({ hash });
    console.log(`  ${label}: gas=${gasUsed.toString()} time=${Date.now() - start}ms`);
  };

  console.log("Authorizing submitter:", submitter.account.address);
  await recordTx("Submitter authorized", () =>
    dataSharing.write.setDataSubmitter([submitter.account.address, true], {
      account: owner.account,
    })
  );
  console.log("");

  // Retrieve ConsentManager for tracking consent identifiers during workflows.
  const consentManagerAddress = await dataSharing.read.consentManager();
  const consentManager = await viem.getContractAt("ConsentManager", consentManagerAddress);

  for (let i = 0; i < 5; i++) {
    const user = users[i];
    const requester = requesters[i];
    const attrs = ATTRIBUTE_SETS[i];
    const duration = DURATIONS[i];
    const score = CREDIT_SCORES[i];

    console.log(`--- Workflow ${i + 1} ---`);
    console.log("User:", user.account.address);
    console.log("Requester:", requester.account.address);

    // Register the user with a deterministic hashed UUID to satisfy IdentityManager.
    await recordTx("User registered", () =>
      dataSharing.write.registerUser([USER_HASHES[i]], {
        account: user.account,
      })
    );

    // Register the requester account so consent checks can pass.
    await recordTx("Requester registered", () =>
      dataSharing.write.registerUser([REQUESTER_HASHES[i]], {
        account: requester.account,
      })
    );

    // Submit an access request with the attribute set assigned to this workflow.
    const requestId = await dataSharing.read.nextRequestId();
    await recordTx("Access request submitted", () =>
      dataSharing.write.requestAccess([user.account.address, attrs], {
        account: requester.account,
      })
    );

    // Grant consent for the configured duration and calculate the resulting ID.
    await recordTx("Consent granted", () =>
      dataSharing.write.grantConsent([requestId, duration], {
        account: user.account,
      })
    );
    const consentId = (await consentManager.read.nextConsentId()) - 1n;
    console.log("  Consent granted (ID:", consentId.toString(), ").");

    // Perform one successful access attempt using the first attribute in the set.
    await recordTx("Access attempt recorded (allowed)", () =>
      dataSharing.write.accessData([consentId, attrs[0]], {
        account: requester.account,
      })
    );

    // Revoke the consent so that subsequent access attempts get denied.
    await recordTx("Consent revoked", () =>
      dataSharing.write.revokeConsent([consentId], {
        account: user.account,
      })
    );

    // Log an access attempt after the revocation to demonstrate denial handling.
    await recordTx("Access attempt after revoke recorded", () =>
      dataSharing.write.accessData([consentId, attrs[0]], {
        account: requester.account,
      })
    );

    // Submit a credit verification update via the authorized submitter.
    await recordTx("Credit verification submitted", () =>
      dataSharing.write.submitCreditVerification(
        [user.account.address, score, toHex(`workflow-${i + 1}-sig`)],
        { account: submitter.account }
      )
    );

    console.log("");
  }

  console.log("All workflows completed. Use the console output for recorded metrics.\n");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
