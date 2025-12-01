import { network } from "hardhat";

async function main() {
  const { viem } = await network.connect();
  const [deployer] = await viem.getWalletClients();

  const dataSharing = await viem.deployContract("DataSharing", [], {
    client: { wallet: deployer },
  });

  console.log("DataSharing:", dataSharing.address);
  console.log("IdentityManager:", await dataSharing.read.identityManager());
  console.log("ConsentManager:", await dataSharing.read.consentManager());
  console.log("AuditLog:", await dataSharing.read.auditLog());
  console.log("AccessToken:", await dataSharing.read.accessToken());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
