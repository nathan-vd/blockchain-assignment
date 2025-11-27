export const bountyBoardAbi = [
  {
    "inputs": [
      { "internalType": "address", "name": "_tokenAddress", "type": "address" },
      { "internalType": "address", "name": "_nftAddress", "type": "address" }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "internalType": "uint256", "name": "bountyId", "type": "uint256" }
    ],
    "name": "BountyCancelled",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "indexed": true, "internalType": "address", "name": "helper", "type": "address" }
    ],
    "name": "BountyClaimed",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "indexed": true, "internalType": "address", "name": "helper", "type": "address" },
      { "indexed": false, "internalType": "uint256", "name": "reward", "type": "uint256" }
    ],
    "name": "BountyCompleted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "indexed": true, "internalType": "address", "name": "requester", "type": "address" },
      { "indexed": false, "internalType": "uint256", "name": "reward", "type": "uint256" },
      { "indexed": false, "internalType": "uint8", "name": "category", "type": "uint8" }
    ],
    "name": "BountyCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "indexed": false, "internalType": "string", "name": "submissionUrl", "type": "string" }
    ],
    "name": "BountySubmitted",
    "type": "event"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" }
    ],
    "name": "approveSolution",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "name": "bounties",
    "outputs": [
      { "internalType": "uint256", "name": "id", "type": "uint256" },
      { "internalType": "address", "name": "requester", "type": "address" },
      { "internalType": "address", "name": "helper", "type": "address" },
      { "internalType": "string", "name": "description", "type": "string" },
      { "internalType": "uint256", "name": "reward", "type": "uint256" },
      { "internalType": "uint8", "name": "category", "type": "uint8" },
      { "internalType": "uint8", "name": "status", "type": "uint8" },
      { "internalType": "uint256", "name": "createdAt", "type": "uint256" },
      { "internalType": "string", "name": "submissionUrl", "type": "string" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "bountyToken",
    "outputs": [
      { "internalType": "contract IERC20", "name": "", "type": "address" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" }
    ],
    "name": "cancelBounty",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" }
    ],
    "name": "claimBounty",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "string", "name": "description", "type": "string" },
      { "internalType": "uint256", "name": "reward", "type": "uint256" },
      { "internalType": "uint8", "name": "category", "type": "uint8" }
    ],
    "name": "createBounty",
    "outputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" }
    ],
    "name": "getBounty",
    "outputs": [
      { "internalType": "address", "name": "requester", "type": "address" },
      { "internalType": "address", "name": "helper", "type": "address" },
      { "internalType": "string", "name": "description", "type": "string" },
      { "internalType": "uint256", "name": "reward", "type": "uint256" },
      { "internalType": "uint8", "name": "category", "type": "uint8" },
      { "internalType": "uint8", "name": "status", "type": "uint8" },
      { "internalType": "string", "name": "submissionUrl", "type": "string" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getEscrowBalance",
    "outputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "helper", "type": "address" }
    ],
    "name": "getHelperBounties",
    "outputs": [
      { "internalType": "uint256[]", "name": "", "type": "uint256[]" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getOpenBounties",
    "outputs": [
      { "internalType": "uint256[]", "name": "", "type": "uint256[]" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "user", "type": "address" }
    ],
    "name": "getUserBounties",
    "outputs": [
      { "internalType": "uint256[]", "name": "", "type": "uint256[]" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "", "type": "address" },
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "name": "helperBounties",
    "outputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "nextBountyId",
    "outputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      { "internalType": "address", "name": "", "type": "address" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "internalType": "string", "name": "reason", "type": "string" }
    ],
    "name": "rejectSolution",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "reputationNFT",
    "outputs": [
      { "internalType": "contract IERC721", "name": "", "type": "address" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "bountyId", "type": "uint256" },
      { "internalType": "string", "name": "submissionUrl", "type": "string" }
    ],
    "name": "submitSolution",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "", "type": "address" },
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "name": "userBounties",
    "outputs": [
      { "internalType": "uint256", "name": "", "type": "uint256" }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;
