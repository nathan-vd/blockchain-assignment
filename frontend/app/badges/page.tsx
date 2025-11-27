"use client";

import { useState, useMemo, useEffect } from "react";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Award, Calendar, Trophy } from "lucide-react";
import { useAccount, useReadContract } from "wagmi";
import { reputationNftAbi } from "@/lib/contracts/reputationNftAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { Category, CATEGORY_NAMES, CATEGORY_COLORS } from "@/lib/types";

export default function BadgesPage() {
  const { address, isConnected } = useAccount();
  const [selectedCategory, setSelectedCategory] = useState<Category | "all">("all");

  // Fetch user's badge IDs
  const { data: badgeIds, isLoading } = useReadContract({
    address: CONTRACTS.ReputationNFT.address as `0x${string}`,
    abi: reputationNftAbi,
    functionName: "getStudentBadges",
    args: address ? [address] : undefined,
  });

  const badges = (badgeIds as bigint[]) || [];

  const filteredBadges = useMemo(() => {
    if (selectedCategory === "all") return badges;
    return badges;
  }, [badges, selectedCategory]);

  // Count badges by category
  const categoryCounts = useMemo(() => {
    const counts: Record<Category, number> = {
      [Category.Math]: 0,
      [Category.Programming]: 0,
      [Category.Writing]: 0,
      [Category.Science]: 0,
      [Category.Language]: 0,
    };

    // We'll calculate this as badges load
    return counts;
  }, [badges]);

  if (!isConnected) {
    return (
      <div className="min-h-screen flex flex-col">
        <Navigation />
        <div className="container mx-auto px-4 py-16">
          <Card>
            <CardContent className="py-12 text-center">
              <Award className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
              <p className="text-muted-foreground">
                Connect your wallet to view your reputation badges
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
          <h1 className="text-4xl font-bold mb-2">Reputation Badges</h1>
          <p className="text-muted-foreground">
            Your soul-bound NFT badges showcasing your skills and achievements
          </p>
        </div>

        {/* Stats Overview */}
        <div className="grid gap-4 md:grid-cols-3 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Badges</CardTitle>
              <Trophy className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{badges.length}</div>
              <p className="text-xs text-muted-foreground">Earned through completed bounties</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Categories</CardTitle>
              <Award className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {Object.values(categoryCounts).filter(c => c > 0).length}
              </div>
              <p className="text-xs text-muted-foreground">Skill areas unlocked</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Latest Badge</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {badges.length > 0 ? "Recent" : "None"}
              </div>
              <p className="text-xs text-muted-foreground">
                {badges.length > 0 ? "Keep completing bounties!" : "Complete a bounty to earn your first badge"}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Category Filter */}
        <div className="mb-6">
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

        {/* Badges Grid */}
        {isLoading ? (
          <div className="text-center py-12">
            <p className="text-muted-foreground">Loading badges...</p>
          </div>
        ) : badges.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <Award className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">No Badges Yet</h3>
              <p className="text-muted-foreground mb-4">
                Complete bounties to earn your first reputation badge!
              </p>
              <Button onClick={() => window.location.href = '/bounties'}>
                Browse Bounties
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {badges.map((badgeId) => (
              <BadgeCard key={badgeId.toString()} badgeId={badgeId} />
            ))}
          </div>
        )}
      </div>

      <Footer />
    </div>
  );
}

function BadgeCard({ badgeId }: { badgeId: bigint }) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Fetch badge details
  const { data: badgeData } = useReadContract({
    address: CONTRACTS.ReputationNFT.address as `0x${string}`,
    abi: reputationNftAbi,
    functionName: "getBadge",
    args: [badgeId],
  });

  if (!badgeData) {
    return null;
  }

  const [student, category, issuedDate, achievement] = badgeData;
  const categoryEnum = category as Category;
  const date = new Date(Number(issuedDate) * 1000);

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <div className="flex justify-between items-start mb-2">
          <Badge className={CATEGORY_COLORS[categoryEnum]}>
            {CATEGORY_NAMES[categoryEnum]}
          </Badge>
          <Award className="h-6 w-6 text-primary" />
        </div>
        <CardTitle className="text-lg">Badge #{badgeId.toString()}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <p className="text-sm font-medium mb-1">Achievement:</p>
          <p className="text-sm text-muted-foreground line-clamp-3">{achievement}</p>
        </div>

        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <Calendar className="h-3 w-3" />
          <span>Earned on {mounted ? date.toLocaleDateString() : "..."}</span>
        </div>

        <div className="pt-2 border-t">
          <p className="text-xs text-muted-foreground">
            Soul-bound NFT - Non-transferable
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
