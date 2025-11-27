"use client";

import { http, createConfig } from "wagmi";
import { hardhat } from "wagmi/chains";

// Custom Hardhat chain for local development
export const localHardhat = {
  ...hardhat,
  id: 31337,
  name: "Hardhat Local",
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:8545"],
    },
  },
};

export const config = createConfig({
  chains: [localHardhat],
  transports: {
    [localHardhat.id]: http(),
  },
});
