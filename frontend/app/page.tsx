"use client";

import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";
import { Coins, Award, FileText, Shield, Users, Zap } from "lucide-react";

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col">
      <Navigation />

      {/* Hero Section */}
      <section className="flex-1 container mx-auto px-4 py-16 md:py-24">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <div className="space-y-4">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Campus Bounty Platform
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground">
              Peer-to-peer task marketplace for students. Post bounties, complete tasks, earn tokens and reputation badges.
            </p>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/bounties">
              <Button size="lg" className="w-full sm:w-auto">
                Browse Bounties
              </Button>
            </Link>
            <Link href="/bounties/create">
              <Button size="lg" variant="outline" className="w-full sm:w-auto">
                Post a Bounty
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="border-t bg-muted/50 py-16">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">
            How It Works
          </h2>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
            <Card>
              <CardHeader>
                <FileText className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Post Bounties</CardTitle>
                <CardDescription>
                  Need help with homework, projects, or tasks? Post a bounty with a token reward.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Users className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Claim & Complete</CardTitle>
                <CardDescription>
                  Browse open bounties, claim ones you can help with, and submit your solution.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Coins className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Earn Tokens</CardTitle>
                <CardDescription>
                  Get paid in Campus Bounty Tokens (CBT) when your solution is approved.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Award className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Build Reputation</CardTitle>
                <CardDescription>
                  Earn skill badges (NFTs) for completing bounties in different categories.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Shield className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Secure Escrow</CardTitle>
                <CardDescription>
                  Tokens are held in escrow until work is approved, ensuring fair payment.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Zap className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Instant Transactions</CardTitle>
                <CardDescription>
                  Powered by blockchain for transparent, instant, and secure transactions.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto px-4 py-16 text-center">
        <div className="max-w-2xl mx-auto space-y-6">
          <h2 className="text-3xl font-bold">
            Ready to Get Started?
          </h2>
          <p className="text-lg text-muted-foreground">
            Connect your wallet to start posting and completing bounties on your campus.
          </p>
          <Link href="/bounties">
            <Button size="lg">
              Explore Bounties
            </Button>
          </Link>
        </div>
      </section>

      <Footer />
    </div>
  );
}
