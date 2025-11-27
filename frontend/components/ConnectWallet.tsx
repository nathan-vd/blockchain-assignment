"use client";

import { useState, useEffect } from "react";
import { useAccount, useConnect, useDisconnect } from "wagmi";
import { injected } from "wagmi/connectors";
import { Button } from "@/components/ui/button";
import { formatAddress } from "@/lib/hardhat-accounts";

export function ConnectWallet() {
  const [mounted, setMounted] = useState(false);
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();

  useEffect(() => {
    setMounted(true);
  }, []);

  // Prevent hydration mismatch by not rendering wallet state until mounted
  if (!mounted) {
    return (
      <Button disabled>
        Connect Wallet
      </Button>
    );
  }

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-2">
        <div className="text-sm bg-muted px-3 py-2 rounded-md">
          {formatAddress(address)}
        </div>
        <Button variant="outline" size="sm" onClick={() => disconnect()}>
          Disconnect
        </Button>
      </div>
    );
  }

  return (
    <Button onClick={() => connect({ connector: injected() })}>
      Connect Wallet
    </Button>
  );
}
