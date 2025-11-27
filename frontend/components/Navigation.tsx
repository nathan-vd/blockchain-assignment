"use client";

import Link from "next/link";
import { ConnectWallet } from "@/components/ConnectWallet";
import { Coins, Award, FileText, DollarSign, Users, FolderOpen } from "lucide-react";
import { Badge } from "@/components/ui/badge";

export function Navigation() {
  return (
    <nav className="border-b bg-background">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2 font-bold text-xl">
              <Coins className="h-6 w-6" />
              Campus Bounty
            </Link>

            <div className="hidden md:flex items-center gap-6">
              <Link
                href="/bounties"
                className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                <FileText className="h-4 w-4" />
                Bounties
              </Link>
              <Link
                href="/my-bounties"
                className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                <FolderOpen className="h-4 w-4" />
                My Bounties
              </Link>
              <Link
                href="/badges"
                className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                <Award className="h-4 w-4" />
                Badges
              </Link>
              <Link
                href="/wallet"
                className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                <Coins className="h-4 w-4" />
                Wallet
              </Link>
              <Link
                href="/accounts"
                className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary transition-colors"
              >
                <Users className="h-4 w-4" />
                Test Accounts
              </Link>
            </div>
          </div>

          <ConnectWallet />
        </div>
      </div>
    </nav>
  );
}
