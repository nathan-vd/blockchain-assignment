"use client";

import { useState, useMemo } from "react";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { FileText, Search, Coins, User, Clock, Plus } from "lucide-react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatEther, parseEther } from "viem";
import { bountyBoardAbi } from "@/lib/contracts/bountyBoardAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { Category, BountyStatus, CATEGORY_NAMES, CATEGORY_COLORS, STATUS_COLORS, STATUS_NAMES } from "@/lib/types";
import { toast } from "sonner";
import Link from "next/link";

interface BountyDetails {
  id: bigint;
  requester: string;
  helper: string;
  description: string;
  reward: bigint;
  category: number;
  status: number;
  submissionUrl: string;
}

export default function BountiesPage() {
  const { address, isConnected } = useAccount();
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<Category | "all">("all");
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Fetch open bounties
  const { data: openBountyIds, isLoading: isLoadingIds, refetch } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getOpenBounties",
  });

  // Fetch bounty details for each ID
  const bountyIds = (openBountyIds as bigint[]) || [];

  // Filter and search bounties
  const filteredBounties = useMemo(() => {
    let filtered = bountyIds;

    return filtered;
  }, [bountyIds, selectedCategory, searchQuery]);

  return (
    <div className="min-h-screen flex flex-col">
      <Navigation />

      <div className="container mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-4xl font-bold mb-2">Bounties Marketplace</h1>
            <p className="text-muted-foreground">
              Browse and claim bounties to earn CBT tokens and reputation badges
            </p>
          </div>
          {isConnected && (
            <Link href="/bounties/create">
              <Button size="lg">
                <Plus className="h-4 w-4 mr-2" />
                Create Bounty
              </Button>
            </Link>
          )}
        </div>

        {/* Search and Filter */}
        <div className="mb-6 space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search bounties by description..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            <Button
              variant={selectedCategory === "all" ? "default" : "outline"}
              size="sm"
              onClick={() => setSelectedCategory("all")}
            >
              All Categories
            </Button>
            {Object.entries(CATEGORY_NAMES).map(([key, name]) => (
              <Button
                key={key}
                variant={selectedCategory === parseInt(key) ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedCategory(parseInt(key) as Category)}
              >
                {name}
              </Button>
            ))}
          </div>
        </div>

        {/* Bounties List */}
        {isLoadingIds ? (
          <div className="text-center py-12">
            <p className="text-muted-foreground">Loading bounties...</p>
          </div>
        ) : bountyIds.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">No Open Bounties</h3>
              <p className="text-muted-foreground mb-4">
                There are no open bounties at the moment. Check back later or create one!
              </p>
              {isConnected && (
                <Link href="/bounties/create">
                  <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    Create First Bounty
                  </Button>
                </Link>
              )}
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {bountyIds.map((bountyId) => (
              <BountyCard key={bountyId.toString()} bountyId={bountyId} onClaim={refetch} />
            ))}
          </div>
        )}

        {!isConnected && (
          <Card className="mt-6 border-yellow-200 bg-yellow-50">
            <CardContent className="py-6">
              <p className="text-sm text-yellow-800">
                <strong>Connect your wallet</strong> to claim bounties and start earning rewards!
              </p>
            </CardContent>
          </Card>
        )}
      </div>

      <Footer />
    </div>
  );
}

function BountyCard({ bountyId, onClaim }: { bountyId: bigint; onClaim: () => void }) {
  const { address, isConnected } = useAccount();

  // Fetch bounty details
  const { data: bountyData } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getBounty",
    args: [bountyId],
  });

  const { writeContract, data: hash, isPending } = useWriteContract();

  const { isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  if (isSuccess && !isPending) {
    toast.success("Bounty claimed successfully!");
    onClaim();
  }

  if (!bountyData) {
    return null;
  }

  const [requester, helper, description, reward, category, status, submissionUrl] = bountyData;

  const handleClaim = async () => {
    if (!isConnected) {
      toast.error("Please connect your wallet first");
      return;
    }

    try {
      writeContract({
        address: CONTRACTS.BountyBoard.address as `0x${string}`,
        abi: bountyBoardAbi,
        functionName: "claimBounty",
        args: [bountyId],
      });
    } catch (error: any) {
      toast.error(error?.message || "Failed to claim bounty");
    }
  };

  const categoryEnum = category as Category;
  const statusEnum = status as BountyStatus;
  const isOwnBounty = address?.toLowerCase() === requester.toLowerCase();

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <div className="flex justify-between items-start mb-2">
          <Badge className={CATEGORY_COLORS[categoryEnum]}>
            {CATEGORY_NAMES[categoryEnum]}
          </Badge>
          <Badge className={STATUS_COLORS[statusEnum]} variant="outline">
            {STATUS_NAMES[statusEnum]}
          </Badge>
        </div>
        <CardTitle className="text-lg line-clamp-2">{description}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <User className="h-4 w-4" />
          <span>By {requester.slice(0, 6)}...{requester.slice(-4)}</span>
        </div>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-lg font-bold text-primary">
            <Coins className="h-5 w-5" />
            {formatEther(reward)} CBT
          </div>
        </div>

        {statusEnum === BountyStatus.Open && (
          <>
            {isOwnBounty ? (
              <Button disabled className="w-full">
                Your Bounty
              </Button>
            ) : (
              <Button
                onClick={handleClaim}
                disabled={!isConnected || isPending}
                className="w-full"
              >
                {isPending ? "Claiming..." : "Claim Bounty"}
              </Button>
            )}
          </>
        )}

        <Link href={`/bounties/${bountyId}`}>
          <Button variant="outline" className="w-full">
            View Details
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}
