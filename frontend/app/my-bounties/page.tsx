"use client";

import { useState } from "react";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { FileText, Coins, User, TrendingUp, Clock } from "lucide-react";
import { useAccount, useReadContract } from "wagmi";
import { formatEther } from "viem";
import { bountyBoardAbi } from "@/lib/contracts/bountyBoardAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { Category, BountyStatus, CATEGORY_NAMES, CATEGORY_COLORS, STATUS_COLORS, STATUS_NAMES } from "@/lib/types";
import Link from "next/link";

export default function MyBountiesPage() {
  const { address, isConnected } = useAccount();

  // Fetch bounties created by user
  const { data: createdBountyIds } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getUserBounties",
    args: address ? [address] : undefined,
  });

  // Fetch bounties claimed by user
  const { data: claimedBountyIds } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getHelperBounties",
    args: address ? [address] : undefined,
  });

  const createdIds = (createdBountyIds as bigint[]) || [];
  const claimedIds = (claimedBountyIds as bigint[]) || [];

  if (!isConnected) {
    return (
      <div className="min-h-screen flex flex-col">
        <Navigation />
        <div className="container mx-auto px-4 py-16">
          <Card>
            <CardContent className="py-12 text-center">
              <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
              <p className="text-muted-foreground">
                Connect your wallet to view your bounties
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

      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-2">My Bounties</h1>
          <p className="text-muted-foreground">
            Track bounties you&apos;ve created and claimed
          </p>
        </div>

        {/* Stats */}
        <div className="grid gap-4 md:grid-cols-3 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Created</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{createdIds.length}</div>
              <p className="text-xs text-muted-foreground">Bounties you posted</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Claimed</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{claimedIds.length}</div>
              <p className="text-xs text-muted-foreground">Bounties you&apos;re working on</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total</CardTitle>
              <Coins className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{createdIds.length + claimedIds.length}</div>
              <p className="text-xs text-muted-foreground">All bounties</p>
            </CardContent>
          </Card>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="created" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="created">
              Bounties I Created ({createdIds.length})
            </TabsTrigger>
            <TabsTrigger value="claimed">
              Bounties I Claimed ({claimedIds.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="created" className="mt-6">
            {createdIds.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                  <h3 className="text-lg font-semibold mb-2">No Bounties Created</h3>
                  <p className="text-muted-foreground mb-4">
                    You haven&apos;t created any bounties yet
                  </p>
                  <Link href="/bounties/create">
                    <Button>Create Your First Bounty</Button>
                  </Link>
                </CardContent>
              </Card>
            ) : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {createdIds.map((bountyId) => (
                  <BountyCard key={bountyId.toString()} bountyId={bountyId} viewType="requester" />
                ))}
              </div>
            )}
          </TabsContent>

          <TabsContent value="claimed" className="mt-6">
            {claimedIds.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <TrendingUp className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                  <h3 className="text-lg font-semibold mb-2">No Bounties Claimed</h3>
                  <p className="text-muted-foreground mb-4">
                    You haven&apos;t claimed any bounties yet
                  </p>
                  <Link href="/bounties">
                    <Button>Browse Available Bounties</Button>
                  </Link>
                </CardContent>
              </Card>
            ) : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {claimedIds.map((bountyId) => (
                  <BountyCard key={bountyId.toString()} bountyId={bountyId} viewType="helper" />
                ))}
              </div>
            )}
          </TabsContent>
        </Tabs>
      </div>

      <Footer />
    </div>
  );
}

function BountyCard({ bountyId, viewType }: { bountyId: bigint; viewType: "requester" | "helper" }) {
  // Fetch bounty details
  const { data: bountyData } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getBounty",
    args: [bountyId],
  });

  if (!bountyData) {
    return null;
  }

  const [requester, helper, description, reward, category, status, submissionUrl] = bountyData;
  const categoryEnum = category as Category;
  const statusEnum = status as BountyStatus;

  const getStatusMessage = () => {
    if (viewType === "requester") {
      switch (statusEnum) {
        case BountyStatus.Open:
          return "Waiting for helper to claim";
        case BountyStatus.Claimed:
          return "Helper is working on it";
        case BountyStatus.Submitted:
          return "Review submission now!";
        case BountyStatus.Completed:
          return "Completed & paid";
        case BountyStatus.Cancelled:
          return "Cancelled & refunded";
        default:
          return "";
      }
    } else {
      switch (statusEnum) {
        case BountyStatus.Claimed:
          return "Submit your work";
        case BountyStatus.Submitted:
          return "Awaiting review";
        case BountyStatus.Completed:
          return "Completed! Payment received";
        default:
          return "";
      }
    }
  };

  const needsAction = (viewType === "requester" && statusEnum === BountyStatus.Submitted) ||
                      (viewType === "helper" && statusEnum === BountyStatus.Claimed);

  return (
    <Card className={`hover:shadow-lg transition-shadow ${needsAction ? "border-primary" : ""}`}>
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
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-lg font-bold text-primary">
            <Coins className="h-5 w-5" />
            {formatEther(reward)} CBT
          </div>
        </div>

        {needsAction && (
          <div className="bg-primary/10 p-2 rounded-md">
            <p className="text-xs font-medium text-primary flex items-center gap-1">
              <Clock className="h-3 w-3" />
              Action needed!
            </p>
          </div>
        )}

        <div className="text-sm text-muted-foreground">
          {getStatusMessage()}
        </div>

        <Link href={`/bounties/${bountyId}`}>
          <Button variant={needsAction ? "default" : "outline"} className="w-full">
            {needsAction ? "Take Action" : "View Details"}
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}
