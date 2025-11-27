import { network } from "hardhat";

async function main() {
  const { viem } = await network.connect();

  const identity = await viem.deployContract("DigitalIdentity");
  console.log("DigitalIdentity:", identity.address);

  const consent = await viem.deployContract("ConsentManager", [identity.address]);
  console.log("ConsentManager:", consent.address);

  const registry = await viem.deployContract("DataAccessRegistry", [consent.address]);
  console.log("DataAccessRegistry:", registry.address);

  const token = await viem.deployContract("AccessToken");
  console.log("AccessToken:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
