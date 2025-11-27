"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { Navigation } from "@/components/Navigation";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Coins, User, Calendar, CheckCircle, XCircle, Send, ExternalLink } from "lucide-react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatEther } from "viem";
import { bountyBoardAbi } from "@/lib/contracts/bountyBoardAbi";
import { CONTRACTS } from "@/lib/contracts/config";
import { Category, BountyStatus, CATEGORY_NAMES, CATEGORY_COLORS, STATUS_COLORS, STATUS_NAMES } from "@/lib/types";
import { toast } from "sonner";
import Link from "next/link";

export default function BountyDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const { address, isConnected } = useAccount();
  const bountyId = BigInt(params.id as string);

  const [submissionUrl, setSubmissionUrl] = useState("");

  // Fetch bounty details
  const { data: bountyData, refetch } = useReadContract({
    address: CONTRACTS.BountyBoard.address as `0x${string}`,
    abi: bountyBoardAbi,
    functionName: "getBounty",
    args: [bountyId],
  });

  // Submit solution
  const { writeContract: submitSolution, data: submitHash, isPending: isSubmitting } = useWriteContract();
  const { isSuccess: isSubmitSuccess } = useWaitForTransactionReceipt({
    hash: submitHash,
  });

  // Approve solution
  const { writeContract: approveSolution, data: approveHash, isPending: isApproving } = useWriteContract();
  const { isSuccess: isApproveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  // Reject solution
  const { writeContract: rejectSolution, data: rejectHash, isPending: isRejecting } = useWriteContract();
  const { isSuccess: isRejectSuccess } = useWaitForTransactionReceipt({
    hash: rejectHash,
  });

  useEffect(() => {
    if (isSubmitSuccess) {
      toast.success("Solution submitted successfully!");
      setSubmissionUrl("");
      refetch();
    }
  }, [isSubmitSuccess, refetch]);

  useEffect(() => {
    if (isApproveSuccess) {
      toast.success("Solution approved! Helper received payment and badge.");
      refetch();
    }
  }, [isApproveSuccess, refetch]);

  useEffect(() => {
    if (isRejectSuccess) {
      toast.success("Solution rejected. Helper can resubmit.");
      refetch();
    }
  }, [isRejectSuccess, refetch]);

  if (!bountyData) {
    return (
      <div className="min-h-screen flex flex-col">
        <Navigation />
        <div className="container mx-auto px-4 py-16">
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">Loading bounty details...</p>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  const [requester, helper, description, reward, category, status, existingSubmissionUrl] = bountyData;
  const categoryEnum = category as Category;
  const statusEnum = status as BountyStatus;

  const isRequester = address?.toLowerCase() === requester.toLowerCase();
  const isHelper = address?.toLowerCase() === helper.toLowerCase();
  const hasHelper = helper !== "0x0000000000000000000000000000000000000000";

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!submissionUrl.trim()) {
      toast.error("Please enter a submission URL");
      return;
    }

    submitSolution({
      address: CONTRACTS.BountyBoard.address as `0x${string}`,
      abi: bountyBoardAbi,
      functionName: "submitSolution",
      args: [bountyId, submissionUrl],
    });
  };

  const handleApprove = () => {
    approveSolution({
      address: CONTRACTS.BountyBoard.address as `0x${string}`,
      abi: bountyBoardAbi,
      functionName: "approveSolution",
      args: [bountyId],
    });
  };

  const handleReject = () => {
    const reason = prompt("Please provide a reason for rejection:");
    if (!reason) {
      toast.error("Rejection reason is required");
      return;
    }

    rejectSolution({
      address: CONTRACTS.BountyBoard.address as `0x${string}`,
      abi: bountyBoardAbi,
      functionName: "rejectSolution",
      args: [bountyId, reason],
    });
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Navigation />

      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <Link href="/bounties">
          <Button variant="ghost" className="mb-4">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Bounties
          </Button>
        </Link>

        <Card className="mb-6">
          <CardHeader>
            <div className="flex justify-between items-start mb-4">
              <div className="flex gap-2">
                <Badge className={CATEGORY_COLORS[categoryEnum]}>
                  {CATEGORY_NAMES[categoryEnum]}
                </Badge>
                <Badge className={STATUS_COLORS[statusEnum]} variant="outline">
                  {STATUS_NAMES[statusEnum]}
                </Badge>
              </div>
              <div className="flex items-center gap-2 text-2xl font-bold text-primary">
                <Coins className="h-6 w-6" />
                {formatEther(reward)} CBT
              </div>
            </div>
            <CardTitle className="text-2xl">Bounty #{bountyId.toString()}</CardTitle>
            <CardDescription className="text-base mt-2">{description}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-sm">
                  <User className="h-4 w-4 text-muted-foreground" />
                  <span className="text-muted-foreground">Requester:</span>
                </div>
                <p className="font-mono text-sm">{requester}</p>
                {isRequester && (
                  <Badge variant="secondary" className="text-xs">You created this</Badge>
                )}
              </div>

              {hasHelper && (
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <span className="text-muted-foreground">Helper:</span>
                  </div>
                  <p className="font-mono text-sm">{helper}</p>
                  {isHelper && (
                    <Badge variant="secondary" className="text-xs">You claimed this</Badge>
                  )}
                </div>
              )}
            </div>

            {existingSubmissionUrl && (
              <div className="pt-4 border-t">
                <div className="flex items-center gap-2 mb-2">
                  <ExternalLink className="h-4 w-4 text-muted-foreground" />
                  <span className="font-medium">Submission:</span>
                </div>
                <a
                  href={existingSubmissionUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary underline break-all"
                >
                  {existingSubmissionUrl}
                </a>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Submit Solution Form (for helper) */}
        {isHelper && statusEnum === BountyStatus.Claimed && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Send className="h-5 w-5" />
                Submit Your Solution
              </CardTitle>
              <CardDescription>
                Provide a link to your completed work (GitHub, Google Drive, etc.)
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="submissionUrl">Submission URL</Label>
                  <Input
                    id="submissionUrl"
                    type="url"
                    placeholder="https://github.com/yourname/solution"
                    value={submissionUrl}
                    onChange={(e) => setSubmissionUrl(e.target.value)}
                    required
                  />
                  <p className="text-xs text-muted-foreground">
                    Enter a link to your completed work. Make sure it's accessible to the requester.
                  </p>
                </div>

                <Button
                  type="submit"
                  size="lg"
                  className="w-full"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Submitting..." : "Submit Solution"}
                </Button>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Review Submission (for requester) */}
        {isRequester && statusEnum === BountyStatus.Submitted && (
          <Card>
            <CardHeader>
              <CardTitle>Review Submission</CardTitle>
              <CardDescription>
                Review the helper&apos;s work and approve or reject the solution
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-muted p-4 rounded-lg">
                <p className="text-sm mb-2">
                  <strong>What happens when you approve:</strong>
                </p>
                <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
                  <li>Helper receives {formatEther(reward)} CBT tokens</li>
                  <li>Helper automatically receives a reputation badge NFT</li>
                  <li>Bounty is marked as completed</li>
                  <li>This action cannot be undone</li>
                </ul>
              </div>

              <div className="flex gap-4">
                <Button
                  onClick={handleApprove}
                  disabled={isApproving}
                  size="lg"
                  className="flex-1"
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {isApproving ? "Approving..." : "Approve & Pay"}
                </Button>
                <Button
                  onClick={handleReject}
                  disabled={isRejecting}
                  variant="destructive"
                  size="lg"
                  className="flex-1"
                >
                  <XCircle className="h-4 w-4 mr-2" />
                  {isRejecting ? "Rejecting..." : "Reject Solution"}
                </Button>
              </div>

              <p className="text-xs text-muted-foreground text-center">
                If you reject, the helper can revise and resubmit their work
              </p>
            </CardContent>
          </Card>
        )}

        {/* Status Messages */}
        {statusEnum === BountyStatus.Completed && (
          <Card className="border-green-200 bg-green-50">
            <CardContent className="py-6">
              <div className="flex items-center gap-2 text-green-800">
                <CheckCircle className="h-5 w-5" />
                <p className="font-medium">
                  This bounty has been completed! {isHelper && "You've earned tokens and a reputation badge!"}
                </p>
              </div>
            </CardContent>
          </Card>
        )}

        {!isConnected && (
          <Card className="border-yellow-200 bg-yellow-50">
            <CardContent className="py-6">
              <p className="text-sm text-yellow-800">
                <strong>Connect your wallet</strong> to interact with this bounty
              </p>
            </CardContent>
          </Card>
        )}

        {isConnected && !isRequester && !isHelper && statusEnum === BountyStatus.Open && (
          <Card className="border-blue-200 bg-blue-50">
            <CardContent className="py-6">
              <p className="text-sm text-blue-800 mb-3">
                This bounty is available to claim!
              </p>
              <Link href="/bounties">
                <Button>Go to Bounties Page to Claim</Button>
              </Link>
            </CardContent>
          </Card>
        )}
      </div>

      <Footer />
    </div>
  );
}
