"use client";

import { useState } from "react";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Coins, Send, CheckCircle, Wallet2, Copy } from "lucide-react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatEther, parseEther, isAddress } from "viem";
import { bountyTokenAbi } from "@/lib/contracts/bountyTokenAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { toast } from "sonner";

export default function WalletPage() {
  const { address, isConnected } = useAccount();
  const [transferTo, setTransferTo] = useState("");
  const [transferAmount, setTransferAmount] = useState("");
  const [approveSpender, setApproveSpender] = useState("");
  const [approveAmount, setApproveAmount] = useState("");

  // Fetch token balance
  const { data: balance, refetch: refetchBalance } = useReadContract({
    address: CONTRACTS.BountyToken.address as `0x${string}`,
    abi: bountyTokenAbi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
  });

  // Transfer tokens
  const { writeContract: transfer, data: transferHash, isPending: isTransferring } = useWriteContract();
  const { isSuccess: isTransferSuccess } = useWaitForTransactionReceipt({
    hash: transferHash,
  });

  // Approve tokens
  const { writeContract: approve, data: approveHash, isPending: isApproving } = useWriteContract();
  const { isSuccess: isApproveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConnected) {
      toast.error("Please connect your wallet");
      return;
    }

    if (!transferTo.trim()) {
      toast.error("Please enter a recipient address");
      return;
    }

    if (!isAddress(transferTo)) {
      toast.error("Invalid recipient address");
      return;
    }

    if (!transferAmount || parseFloat(transferAmount) <= 0) {
      toast.error("Please enter a valid amount");
      return;
    }

    try {
      transfer({
        address: CONTRACTS.BountyToken.address as `0x${string}`,
        abi: bountyTokenAbi,
        functionName: "transfer",
        args: [transferTo as `0x${string}`, parseEther(transferAmount)],
      });
    } catch (error: any) {
      toast.error(error?.message || "Failed to transfer tokens");
    }
  };

  const handleApprove = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConnected) {
      toast.error("Please connect your wallet");
      return;
    }

    if (!approveSpender.trim()) {
      toast.error("Please enter a spender address");
      return;
    }

    if (!isAddress(approveSpender)) {
      toast.error("Invalid spender address");
      return;
    }

    if (!approveAmount || parseFloat(approveAmount) <= 0) {
      toast.error("Please enter a valid amount");
      return;
    }

    try {
      approve({
        address: CONTRACTS.BountyToken.address as `0x${string}`,
        abi: bountyTokenAbi,
        functionName: "approve",
        args: [approveSpender as `0x${string}`, parseEther(approveAmount)],
      });
    } catch (error: any) {
      toast.error(error?.message || "Failed to approve tokens");
    }
  };

  if (isTransferSuccess) {
    toast.success("Tokens transferred successfully!");
    setTransferTo("");
    setTransferAmount("");
    refetchBalance();
  }

  if (isApproveSuccess) {
    toast.success("Token approval successful!");
    setApproveSpender("");
    setApproveAmount("");
  }

  const copyAddress = () => {
    if (address) {
      navigator.clipboard.writeText(address);
      toast.success("Address copied to clipboard!");
    }
  };

  const setMaxTransfer = () => {
    if (balance) {
      setTransferAmount(formatEther(balance as bigint));
    }
  };

  const setMaxApprove = () => {
    if (balance) {
      setApproveAmount(formatEther(balance as bigint));
    }
  };

  if (!isConnected) {
    return (
      <div className="min-h-screen flex flex-col">
        <Navigation />
        <div className="container mx-auto px-4 py-16">
          <Card>
            <CardContent className="py-12 text-center">
              <Wallet2 className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
              <p className="text-muted-foreground">
                Connect your wallet to manage your CBT tokens
              </p>
            </CardContent>
          </Card>
        </div>
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Navigation />

      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-2">Token Wallet</h1>
          <p className="text-muted-foreground">
            Manage your Campus Bounty Tokens (CBT)
          </p>
        </div>

        {/* Balance Card */}
        <Card className="mb-8 bg-gradient-to-br from-primary/10 to-primary/5">
          <CardHeader>
            <CardTitle>Your Balance</CardTitle>
            <CardDescription>Campus Bounty Token (CBT)</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Coins className="h-12 w-12 text-primary" />
                <div>
                  <p className="text-4xl font-bold">
                    {balance ? formatEther(balance as bigint) : "0"}
                  </p>
                  <p className="text-sm text-muted-foreground">CBT</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm text-muted-foreground mb-2">Your Address</p>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={copyAddress}
                  className="gap-2"
                >
                  <span className="font-mono text-xs">
                    {address?.slice(0, 6)}...{address?.slice(-4)}
                  </span>
                  <Copy className="h-3 w-3" />
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Actions */}
        <Tabs defaultValue="transfer" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="transfer">Transfer Tokens</TabsTrigger>
            <TabsTrigger value="approve">Approve Spending</TabsTrigger>
          </TabsList>

          <TabsContent value="transfer">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Send className="h-5 w-5" />
                  Transfer Tokens
                </CardTitle>
                <CardDescription>
                  Send CBT tokens to another address
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleTransfer} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="transferTo">Recipient Address</Label>
                    <Input
                      id="transferTo"
                      placeholder="0x..."
                      value={transferTo}
                      onChange={(e) => setTransferTo(e.target.value)}
                      required
                    />
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <Label htmlFor="transferAmount">Amount (CBT)</Label>
                      <Button
                        type="button"
                        variant="link"
                        size="sm"
                        onClick={setMaxTransfer}
                        className="h-auto p-0"
                      >
                        Max
                      </Button>
                    </div>
                    <Input
                      id="transferAmount"
                      type="number"
                      step="0.01"
                      min="0.01"
                      placeholder="10"
                      value={transferAmount}
                      onChange={(e) => setTransferAmount(e.target.value)}
                      required
                    />
                    <p className="text-xs text-muted-foreground">
                      Available: {balance ? formatEther(balance as bigint) : "0"} CBT
                    </p>
                  </div>

                  <Button
                    type="submit"
                    size="lg"
                    className="w-full"
                    disabled={isTransferring}
                  >
                    {isTransferring ? (
                      "Transferring..."
                    ) : (
                      <>
                        <Send className="h-4 w-4 mr-2" />
                        Transfer Tokens
                      </>
                    )}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="approve">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5" />
                  Approve Token Spending
                </CardTitle>
                <CardDescription>
                  Allow a contract or address to spend your tokens
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleApprove} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="approveSpender">Spender Address</Label>
                    <Input
                      id="approveSpender"
                      placeholder="0x..."
                      value={approveSpender}
                      onChange={(e) => setApproveSpender(e.target.value)}
                      required
                    />
                    <p className="text-xs text-muted-foreground">
                      BountyBoard: {CONTRACTS.BountyBoard.address}
                    </p>
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <Label htmlFor="approveAmount">Amount (CBT)</Label>
                      <Button
                        type="button"
                        variant="link"
                        size="sm"
                        onClick={setMaxApprove}
                        className="h-auto p-0"
                      >
                        Max
                      </Button>
                    </div>
                    <Input
                      id="approveAmount"
                      type="number"
                      step="0.01"
                      min="0.01"
                      placeholder="100"
                      value={approveAmount}
                      onChange={(e) => setApproveAmount(e.target.value)}
                      required
                    />
                  </div>

                  <div className="bg-muted p-4 rounded-lg">
                    <p className="text-sm text-muted-foreground">
                      Approving tokens allows the spender to transfer tokens on your behalf.
                      This is required when creating bounties.
                    </p>
                  </div>

                  <Button
                    type="submit"
                    size="lg"
                    className="w-full"
                    disabled={isApproving}
                  >
                    {isApproving ? (
                      "Approving..."
                    ) : (
                      <>
                        <CheckCircle className="h-4 w-4 mr-2" />
                        Approve Tokens
                      </>
                    )}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Quick Info */}
        <Card className="mt-6">
          <CardHeader>
            <CardTitle className="text-lg">Token Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Token Name:</span>
              <span className="font-medium">Campus Bounty Token</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Symbol:</span>
              <span className="font-medium">CBT</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Decimals:</span>
              <span className="font-medium">18</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Contract:</span>
              <span className="font-mono text-xs">{CONTRACTS.BountyToken.address}</span>
            </div>
          </CardContent>
        </Card>
      </div>

      <Footer />
    </div>
  );
}
