# Campus Bounty Platform

A decentralized application (DApp) for managing academic bounties, built on Ethereum. Students can post tasks, helpers can claim and complete them, earning both tokens and soul-bound reputation badges (NFTs).

**Developer:** Ankur Lohachab
**Course:** Introduction to Blockchains, DACS
**Institution:** Maastricht University

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Smart Contracts](#smart-contracts)
- [Getting Started](#getting-started)
- [Usage Guide](#usage-guide)
- [Project Structure](#project-structure)
- [Development](#development)
- [License](#license)

---

## Overview

Campus Bounty Platform is a blockchain-based marketplace where students can:
- **Post bounties** for academic help (tutoring, problem-solving, code review, etc.)
- **Claim bounties** and earn CBT (Campus Bounty Tokens)
- **Build reputation** through non-transferable NFT badges
- **Track progress** via a comprehensive dashboard

The platform uses smart contracts to ensure trustless escrow, automatic payments, and verifiable reputation building.

---

## Features

### Core Functionality

#### 1. Bounty Marketplace
- Browse available bounties with filtering and search
- Filter by category: Math, Programming, Writing, Science, Language
- Real-time status updates (Open, Claimed, Submitted, Completed, Cancelled)
- Claim mechanism with automatic helper assignment

#### 2. Bounty Creation & Management
- Create bounties with custom descriptions and rewards
- Automatic token escrow through smart contract
- Two-step approval process (token approval → bounty creation)
- View and manage all your posted bounties

#### 3. Work Submission & Review
- Helpers submit solutions via URL (GitHub, Google Drive, etc.)
- Requesters review and approve/reject submissions
- Rejection allows helpers to revise and resubmit
- Approval triggers automatic payment and badge issuance

#### 4. Reputation System
- Soul-bound NFT badges (non-transferable)
- Automatic badge issuance on bounty completion
- Category-specific badges for skill verification
- Permanent on-chain reputation records

#### 5. Token Management
- View CBT token balance
- Transfer tokens to other addresses
- Approve spending for contract interactions
- Real-time balance updates

#### 6. Personal Dashboard
- Track bounties you've created
- Monitor bounties you've claimed
- "Action needed" indicators for pending tasks
- Separate views for requester and helper roles

---

## Technology Stack

### Blockchain
- **Smart Contracts:** Solidity 0.8.30
- **Development Framework:** Hardhat
- **Local Blockchain:** Hardhat Node
- **Deployment:** Hardhat Ignition

### Frontend
- **Framework:** Next.js 16 (App Router)
- **Language:** TypeScript
- **Styling:** Tailwind CSS
- **UI Components:** shadcn/ui
- **Web3 Library:** Wagmi + Viem
- **State Management:** React Hooks

### Development Tools
- **Package Manager:** npm
- **Build Tool:** Turbopack
- **Code Quality:** TypeScript strict mode

---

## Smart Contracts

The platform deploys four smart contracts to your local Hardhat network. Contract addresses will be displayed in your terminal after deployment.

### 1. BountyToken (ERC-20)
Campus Bounty Token (CBT) for bounty payments:
- Standard ERC-20 implementation with 18 decimals
- Owner can mint and airdrop tokens to students
- Used for all bounty rewards and payments

### 2. ReputationNFT (ERC-721)
Soul-bound reputation badges (non-transferable):
- Five categories: Math, Programming, Writing, Science, Language
- Automatically issued when bounties are completed
- Permanent on-chain reputation records

### 3. BountyBoard
Main contract managing the complete bounty lifecycle:

**Key Functions:**
- `createBounty()` - Post a new bounty with token escrow
- `claimBounty()` - Claim an open bounty
- `submitSolution()` - Submit your work
- `approveSolution()` - Approve work and release payment + badge
- `rejectSolution()` - Reject work for revision
- `cancelBounty()` - Cancel and get refund

**Bounty Status Flow:**
Open → Claimed → Submitted → Completed (or Cancelled)

### 4. EscrowManager
Escrow system with dispute resolution features (not currently integrated in frontend).

---

## Getting Started

Follow these steps to run the Campus Bounty Platform on your local machine.

### Prerequisites

Before you begin, make sure you have:
- **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
- **npm** (comes with Node.js)
- **MetaMask** browser extension - [Install here](https://metamask.io/)
- **Git** - [Download here](https://git-scm.com/)

### Quick Start Guide

#### Step 1: Clone the Repository
```bash
git clone <your-repository-url>
cd LAB_DEMO
```

#### Step 2: Install Dependencies
Install both backend (Hardhat) and frontend (Next.js) dependencies:
```bash
# Install Hardhat dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
cd ..
```

#### Step 3: Start Local Blockchain (Terminal 1)
Start a local Hardhat node that simulates an Ethereum blockchain:
```bash
npx hardhat node
```

**Important:**
- Keep this terminal running
- You'll see 10 test accounts with private keys displayed
- These accounts have test ETH for transactions

#### Step 4: Deploy Smart Contracts (Terminal 2)
Open a new terminal and deploy the contracts:
```bash
npx hardhat ignition deploy ./ignition/modules/Deploy.ts --network localhost
```

**Important:**
- After deployment, you'll see contract addresses in the terminal
- Note these addresses - they're unique to your deployment
- The frontend will automatically connect to these contracts

#### Step 5: Distribute Test Tokens (Terminal 2)
Give all test accounts some Campus Bounty Tokens (CBT):
```bash
npx hardhat run scripts/distribute-tokens.ts --network localhost
```

This gives each of the 10 test accounts 1000 CBT tokens to use.

#### Step 6: Start the Frontend (Terminal 3)
Open a third terminal and start the Next.js development server:
```bash
cd frontend
npm run dev
```

The application will be available at `http://localhost:3000`

#### Step 7: Open the Application
Open your browser and navigate to:
```
http://localhost:3000
```

### MetaMask Setup

1. **Add Hardhat Network:**
   - Open MetaMask
   - Networks → Add Network → Add manually
   - Network Name: `Hardhat Local`
   - RPC URL: `http://127.0.0.1:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **Import Test Account:**
   - Go to `http://localhost:3000/accounts`
   - Copy any private key
   - MetaMask → Account icon → Import Account
   - Paste private key
   - Account now has test ETH and CBT tokens

3. **Connect to DApp:**
   - Click "Connect Wallet" in the top right
   - Approve connection in MetaMask
   - You're ready to use the platform!

---

## Usage Guide

### Complete Bounty Workflow

#### As a Requester (Posting Bounties):

1. **Create a Bounty**
   - Navigate to "Bounties" → "Create Bounty"
   - Fill in description (what you need help with)
   - Select category (Math, Programming, etc.)
   - Set reward amount in CBT
   - Click "Create Bounty"
   - Approve two transactions:
     - Token approval for BountyBoard contract
     - Bounty creation (locks tokens in escrow)

2. **Track Your Bounty**
   - Go to "My Bounties" → "Bounties I Created"
   - Monitor status: waiting for helper, work in progress, or submitted

3. **Review Submission**
   - Receive notification when helper submits work
   - Click "Take Action" on bounty card
   - Review the submission URL
   - Choose to approve or reject:
     - **Approve:** Releases payment + issues badge to helper
     - **Reject:** Allows helper to revise and resubmit

#### As a Helper (Completing Bounties):

1. **Find a Bounty**
   - Browse "Bounties" marketplace
   - Use filters to find relevant categories
   - Search by keywords in descriptions
   - Click "Claim Bounty" on any open bounty

2. **Submit Your Work**
   - Go to "My Bounties" → "Bounties I Claimed"
   - Click "Take Action" on claimed bounty
   - Enter submission URL (GitHub, Google Drive, etc.)
   - Click "Submit Solution"

3. **Receive Rewards**
   - Wait for requester approval
   - Upon approval, you automatically receive:
     - CBT tokens (reward amount)
     - Reputation badge NFT
   - Check "Wallet" for token balance
   - Check "Badges" for your new NFT

### Token Management

#### Transfer Tokens:
1. Go to "Wallet"
2. Click "Transfer Tokens" tab
3. Enter recipient address
4. Enter amount (use "Max" for full balance)
5. Confirm transaction

#### Approve Spending:
1. Go to "Wallet"
2. Click "Approve Spending" tab
3. Enter spender address (e.g., BountyBoard contract)
4. Enter approval amount
5. Confirm transaction
6. Required before creating bounties

### Viewing Reputation

1. Navigate to "Badges"
2. See all earned reputation NFTs
3. Filter by category
4. View stats: total badges, categories unlocked
5. Each badge shows:
   - Category and achievement
   - Date earned
   - Soul-bound status (non-transferable)

---

## Project Structure

```
LAB_DEMO/
├── contracts/                  # Smart contracts
│   ├── BountyBoard.sol        # Main bounty management
│   ├── BountyToken.sol        # ERC-20 token
│   ├── ReputationNFT.sol      # ERC-721 badges
│   └── EscrowManager.sol      # Advanced escrow
├── ignition/
│   └── modules/
│       └── Deploy.ts          # Contract deployment script
├── scripts/
│   └── distribute-tokens.ts   # Token distribution utility
├── frontend/
│   ├── app/                   # Next.js pages
│   │   ├── page.tsx          # Home/landing page
│   │   ├── bounties/
│   │   │   ├── page.tsx      # Marketplace
│   │   │   ├── create/       # Bounty creation
│   │   │   └── [id]/         # Bounty details
│   │   ├── my-bounties/      # Personal dashboard
│   │   ├── badges/           # Reputation viewer
│   │   ├── wallet/           # Token management
│   │   └── accounts/         # Test accounts
│   ├── components/
│   │   ├── Navigation.tsx    # Header navigation
│   │   ├── ConnectWallet.tsx # Wallet connection
│   │   └── ui/               # shadcn/ui components
│   └── lib/
│       ├── contracts/        # ABIs and config
│       ├── types.ts          # TypeScript types
│       ├── wagmi.ts          # Web3 configuration
│       └── hardhat-accounts.ts # Test accounts data
├── hardhat.config.ts         # Hardhat configuration
└── package.json              # Project dependencies
```

---

## Development

### Running Tests

```bash
# Compile contracts
npx hardhat compile

# Run contract tests (if available)
npx hardhat test

# Run with gas reporting
REPORT_GAS=true npx hardhat test
```

### Contract Interaction

```bash
# Open Hardhat console
npx hardhat console --network localhost

# Example: Check token balance (use your deployed contract address)
const Token = await ethers.getContractAt("BountyToken", "YOUR_DEPLOYED_TOKEN_ADDRESS");
await Token.balanceOf("0xYourAddress");
```

### Frontend Development

```bash
cd frontend

# Start dev server with turbopack
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Common Issues

**Issue:** MetaMask shows wrong nonce
**Solution:** Settings → Advanced → Clear activity tab data

**Issue:** Transactions failing
**Solution:** Ensure Hardhat node is running and contracts are deployed

**Issue:** Page shows "Loading..." or contract errors
**Solution:**
- Check browser console for errors
- Verify Hardhat node is running in Terminal 1
- Ensure contracts were deployed successfully in Terminal 2
- Contract addresses are automatically configured after deployment

**Issue:** Can't claim own bounty
**Solution:** This is intentional. Use a different account to claim.

### Dependency Compatibility Note (Wagmi + RainbowKit)

If you face a version mismatch error between Wagmi and RainbowKit, try installing the following compatible versions:

```bash
npm install wagmi@^2.12.0 @rainbow-me/rainbowkit@^2.2.9
```


---

## Key Features Implementation

### Escrow Mechanism
When a bounty is created, tokens are transferred from the requester to the BountyBoard contract, ensuring funds are available when work is approved.

### Soul-Bound Badges
Reputation NFTs override `transferFrom` and `safeTransferFrom` to prevent transfers, making them permanently tied to the earning address.

### Automatic Badge Issuance
The `approveSolution` function in BountyBoard calls `issueBadge` on the ReputationNFT contract, ensuring badges are issued atomically with payment.

### Status-Driven UI
The frontend adapts based on:
- User's role (requester vs helper)
- Bounty status (open, claimed, submitted, completed)
- Connection status (wallet connected or not)

---

## Security Considerations

### Smart Contracts
- Input validation on all public functions
- Reentrancy protection through checks-effects-interactions pattern
- Access control with owner and issuer roles
- Token approval required before escrow

### Frontend
- Address validation before transfers
- Amount validation for token operations
- Transaction confirmation prompts
- Error handling for failed transactions

### Suggestions
- Use test accounts for development only
- Never commit private keys
- Verify contract addresses before transactions
- Test on local network before mainnet deployment

---

## Contributing

This is an academic project. For suggestions or issues:
1. Document the problem clearly
2. Provide steps to reproduce
3. Include relevant error messages or screenshots

---

## License

This project was created as part of a lab session for the course **Introduction to Blockchains, DACS** at **Maastricht University**.

**Developer:** Ankur Lohachab

For educational purposes only. Use at your own risk.

---

## Acknowledgments

- **Course:** Introduction to Blockchains, DACS
- **Institution:** Maastricht University
- **Frameworks:** Hardhat, Next.js, Wagmi
- **UI Components:** shadcn/ui
- **Inspiration:** Decentralized freelancing platforms and academic collaboration tools

---

## Contact

**Developer:** Ankur Lohachab
**Course:** Introduction to Blockchains, DACS
**Institution:** Maastricht University

For academic inquiries related to this project, please refer to the course materials.

---

**Developed by Ankur Lohachab**

Built for blockchain education
