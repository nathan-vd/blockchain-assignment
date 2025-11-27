export enum Category {
  Math = 0,
  Programming = 1,
  Writing = 2,
  Science = 3,
  Language = 4
}

export enum BountyStatus {
  Open = 0,
  Claimed = 1,
  Submitted = 2,
  Completed = 3,
  Cancelled = 4
}

export interface Bounty {
  id: bigint;
  requester: string;
  helper: string;
  description: string;
  reward: bigint;
  category: Category;
  status: BountyStatus;
  createdAt: bigint;
  submissionUrl: string;
}

export interface Badge {
  id: bigint;
  student: string;
  category: Category;
  issuedDate: bigint;
  achievement: string;
}

export const CATEGORY_NAMES: Record<Category, string> = {
  [Category.Math]: "Math",
  [Category.Programming]: "Programming",
  [Category.Writing]: "Writing",
  [Category.Science]: "Science",
  [Category.Language]: "Language"
};

export const STATUS_NAMES: Record<BountyStatus, string> = {
  [BountyStatus.Open]: "Open",
  [BountyStatus.Claimed]: "Claimed",
  [BountyStatus.Submitted]: "Submitted",
  [BountyStatus.Completed]: "Completed",
  [BountyStatus.Cancelled]: "Cancelled"
};

export const CATEGORY_COLORS: Record<Category, string> = {
  [Category.Math]: "bg-blue-100 text-blue-800 border-blue-200",
  [Category.Programming]: "bg-purple-100 text-purple-800 border-purple-200",
  [Category.Writing]: "bg-green-100 text-green-800 border-green-200",
  [Category.Science]: "bg-orange-100 text-orange-800 border-orange-200",
  [Category.Language]: "bg-pink-100 text-pink-800 border-pink-200"
};

export const STATUS_COLORS: Record<BountyStatus, string> = {
  [BountyStatus.Open]: "bg-green-100 text-green-800",
  [BountyStatus.Claimed]: "bg-blue-100 text-blue-800",
  [BountyStatus.Submitted]: "bg-yellow-100 text-yellow-800",
  [BountyStatus.Completed]: "bg-gray-100 text-gray-800",
  [BountyStatus.Cancelled]: "bg-red-100 text-red-800"
};
