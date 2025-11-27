"use client";

import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { HARDHAT_ACCOUNTS, copyToClipboard } from "@/lib/hardhat-accounts";
import { Copy, Check, Wallet } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

export default function AccountsPage() {
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const handleCopy = async (text: string, index: number) => {
    const success = await copyToClipboard(text);
    if (success) {
      setCopiedIndex(index);
      toast.success("Copied to clipboard!");
      setTimeout(() => setCopiedIndex(null), 2000);
    } else {
      toast.error("Failed to copy");
    }
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Navigation />

      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto space-y-6">
          <div className="space-y-2">
            <h1 className="text-3xl font-bold">Test Accounts</h1>
            <p className="text-muted-foreground">
              Hardhat provides these test accounts with 10,000 ETH each. Import them into MetaMask for testing.
            </p>
          </div>

          <Card className="border-yellow-200 bg-yellow-50 dark:bg-yellow-950 dark:border-yellow-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Wallet className="h-5 w-5" />
                How to Import Accounts
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <ol className="list-decimal list-inside space-y-1">
                <li>Open MetaMask and click the account icon</li>
                <li>Select &quot;Import Account&quot;</li>
                <li>Paste the private key from below</li>
                <li>Make sure you&apos;re connected to Hardhat network (Chain ID: 31337)</li>
              </ol>
            </CardContent>
          </Card>

          <div className="grid gap-4">
            {HARDHAT_ACCOUNTS.map((account, index) => (
              <Card key={account.address}>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="text-lg">{account.name}</span>
                    <span className="text-sm font-normal text-muted-foreground">
                      {account.balance}
                    </span>
                  </CardTitle>
                  <CardDescription className="font-mono text-xs">
                    {account.address}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Address</label>
                    <div className="flex gap-2">
                      <code className="flex-1 p-2 rounded bg-muted text-xs break-all">
                        {account.address}
                      </code>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleCopy(account.address, index * 2)}
                      >
                        {copiedIndex === index * 2 ? (
                          <Check className="h-4 w-4" />
                        ) : (
                          <Copy className="h-4 w-4" />
                        )}
                      </Button>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">Private Key</label>
                    <div className="flex gap-2">
                      <code className="flex-1 p-2 rounded bg-muted text-xs break-all">
                        {account.privateKey}
                      </code>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleCopy(account.privateKey, index * 2 + 1)}
                      >
                        {copiedIndex === index * 2 + 1 ? (
                          <Check className="h-4 w-4" />
                        ) : (
                          <Copy className="h-4 w-4" />
                        )}
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          <Card className="border-red-200 bg-red-50 dark:bg-red-950 dark:border-red-800">
            <CardHeader>
              <CardTitle className="text-red-900 dark:text-red-100">
                ⚠️ Warning
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm text-red-900 dark:text-red-100">
              <p>
                These are test accounts only! Never use these private keys on mainnet or with real funds.
                Anyone can access these accounts as they are publicly known.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      <Footer />
    </div>
  );
}
