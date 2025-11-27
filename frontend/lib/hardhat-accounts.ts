/**
 * Hardhat Test Accounts
 * These are the default accounts provided by Hardhat with 10,000 ETH each
 * Use these for testing your DApp locally
 */

export interface HardhatAccount {
  name: string;
  address: `0x${string}`;
  privateKey: `0x${string}`;
  balance: string;
}

export const HARDHAT_ACCOUNTS: HardhatAccount[] = [
  {
    name: "Account #0 (Deployer)",
    address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    privateKey: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    balance: "10000 ETH",
  },
  {
    name: "Account #1 (Alice)",
    address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    privateKey: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    balance: "10000 ETH",
  },
  {
    name: "Account #2 (Bob)",
    address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    privateKey: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
    balance: "10000 ETH",
  },
  {
    name: "Account #3 (Charlie)",
    address: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    privateKey: "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
    balance: "10000 ETH",
  },
  {
    name: "Account #4 (Diana)",
    address: "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    privateKey: "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
    balance: "10000 ETH",
  },
  {
    name: "Account #5 (Eve)",
    address: "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    privateKey: "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
    balance: "10000 ETH",
  },
  {
    name: "Account #6 (Frank)",
    address: "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
    privateKey: "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
    balance: "10000 ETH",
  },
  {
    name: "Account #7 (Grace)",
    address: "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
    privateKey: "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
    balance: "10000 ETH",
  },
  {
    name: "Account #8 (Henry)",
    address: "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
    privateKey: "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97",
    balance: "10000 ETH",
  },
  {
    name: "Account #9 (Ivy)",
    address: "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
    privateKey: "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6",
    balance: "10000 ETH",
  },
];

/**
 * Get account by address
 */
export function getAccountByAddress(address: string): HardhatAccount | undefined {
  return HARDHAT_ACCOUNTS.find(
    (acc) => acc.address.toLowerCase() === address.toLowerCase()
  );
}

/**
 * Get account name by address (for display purposes)
 */
export function getAccountName(address: string): string {
  const account = getAccountByAddress(address);
  return account ? account.name : `${address.slice(0, 6)}...${address.slice(-4)}`;
}

/**
 * Format address for display
 */
export function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

/**
 * Copy to clipboard helper
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (err) {
    console.error("Failed to copy:", err);
    return false;
  }
}
