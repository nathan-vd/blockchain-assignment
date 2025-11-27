"use client";

import { useState, useEffect } from "react";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ArrowLeft, Plus } from "lucide-react";
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from "wagmi";
import { parseEther } from "viem";
import { bountyBoardAbi } from "@/lib/contracts/bountyBoardAbi";
import { bountyTokenAbi } from "@/lib/contracts/bountyTokenAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { Category, CATEGORY_NAMES } from "@/lib/types";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function CreateBountyPage() {
  const router = useRouter();
  const { address, isConnected } = useAccount();
  const [description, setDescription] = useState("");
  const [reward, setReward] = useState("");
  const [category, setCategory] = useState<string>("");
  const [isApproving, setIsApproving] = useState(false);

  const { writeContract: approveTokens, data: approveHash } = useWriteContract();
  const { writeContract: createBounty, data: createHash, isPending: isCreating } = useWriteContract();

  const { isSuccess: isApproveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  const { isSuccess: isCreateSuccess } = useWaitForTransactionReceipt({
    hash: createHash,
  });

  // Check token balance
  const { data: balance } = useReadContract({
    address: CONTRACTS.BountyToken.address as `0x${string}`,
    abi: bountyTokenAbi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isConnected) {
      toast.error("Please connect your wallet");
      return;
    }

    if (!description.trim()) {
      toast.error("Please enter a description");
      return;
    }

    if (!reward || parseFloat(reward) <= 0) {
      toast.error("Please enter a valid reward amount");
      return;
    }

    if (!category) {
      toast.error("Please select a category");
      return;
    }

    try {
      const rewardAmount = parseEther(reward);

      // First approve tokens
      setIsApproving(true);
      approveTokens({
        address: CONTRACTS.BountyToken.address as `0x${string}`,
        abi: bountyTokenAbi,
        functionName: "approve",
        args: [CONTRACTS.BountyBoard.address as `0x${string}`, rewardAmount],
      });
    } catch (error: any) {
      setIsApproving(false);
      toast.error(error?.message || "Failed to approve tokens");
    }
  };

  // Handle token approval success
  useEffect(() => {
    if (isApproveSuccess && isApproving) {
      setIsApproving(false);
      toast.success("Tokens approved! Creating bounty...");

      try {
        createBounty({
          address: CONTRACTS.BountyBoard.address as `0x${string}`,
          abi: bountyBoardAbi,
          functionName: "createBounty",
          args: [description, parseEther(reward), parseInt(category)],
        });
      } catch (error: any) {
        toast.error(error?.message || "Failed to create bounty");
      }
    }
  }, [isApproveSuccess, isApproving, description, reward, category, createBounty]);

  // Handle bounty creation success
  useEffect(() => {
    if (isCreateSuccess) {
      toast.success("Bounty created successfully!");
      router.push("/bounties");
    }
  }, [isCreateSuccess, router]);

  if (!isConnected) {
    return (
      <div className="min-h-screen flex flex-col">
        <Navigation />
        <div className="container mx-auto px-4 py-16">
          <Card>
            <CardContent className="py-12 text-center">
              <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
              <p className="text-muted-foreground">
                Please connect your wallet to create a bounty
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

      <div className="container mx-auto px-4 py-8 max-w-2xl">
        <Link href="/bounties">
          <Button variant="ghost" className="mb-4">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Bounties
          </Button>
        </Link>

        <Card>
          <CardHeader>
            <CardTitle className="text-2xl">Create New Bounty</CardTitle>
            <CardDescription>
              Post a bounty to get help with your task. Helpers earn tokens and reputation badges!
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  placeholder="Describe what you need help with..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={5}
                  required
                />
                <p className="text-xs text-muted-foreground">
                  Be specific about what needs to be done and any requirements
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="category">Category</Label>
                <Select value={category} onValueChange={setCategory} required>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a category" />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(CATEGORY_NAMES).map(([key, name]) => (
                      <SelectItem key={key} value={key}>
                        {name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="reward">Reward (CBT)</Label>
                <Input
                  id="reward"
                  type="number"
                  step="0.01"
                  min="0.01"
                  placeholder="10"
                  value={reward}
                  onChange={(e) => setReward(e.target.value)}
                  required
                />
                <p className="text-xs text-muted-foreground">
                  Your balance: {balance ? (Number(balance) / 1e18).toFixed(2) : "0"} CBT
                </p>
              </div>

              <div className="bg-muted p-4 rounded-lg space-y-2">
                <h4 className="font-medium text-sm">How it works:</h4>
                <ul className="text-xs text-muted-foreground space-y-1">
                  <li>1. Your tokens will be held in escrow until the bounty is completed</li>
                  <li>2. Helpers can claim your bounty and submit their work</li>
                  <li>3. Review and approve the submission to release payment</li>
                  <li>4. Helper receives tokens and a reputation badge automatically</li>
                </ul>
              </div>

              <Button
                type="submit"
                size="lg"
                className="w-full"
                disabled={isApproving || isCreating}
              >
                {isApproving ? (
                  "Approving Tokens..."
                ) : isCreating ? (
                  "Creating Bounty..."
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Create Bounty
                  </>
                )}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>

      <Footer />
    </div>
  );
}
