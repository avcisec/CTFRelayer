# CTFRelayer Frontend Integration Guide

## Overview

**CTFRelayer** is a LayerZero V2-based cross-chain relayer that bridges UMA CTF Adapter operations to HyperEVM's Conditional Tokens Framework (CTF). This module enables Polymarket-style prediction markets on HyperEVM by relaying conditional token creation and resolution operations across chains.

### Problem Solved

- **UMA Oracle Limitation**: UMA oracle is not supported on HyperEVM network
- **Cross-chain CTF Operations**: Need to relay `prepareCondition` and `reportPayouts` operations from source chains to HyperEVM
- **LayerZero Integration**: Uses LayerZero V2 for secure cross-chain messaging

### Key Features

- ✅ Cross-chain conditional token preparation
- ✅ Cross-chain payout reporting
- ✅ Fee estimation for cross-chain operations
- ✅ LayerZero V2 integration with OApp pattern
- ✅ Owner-controlled peer configuration
- ✅ Gas-optimized message options

## Architecture

```
┌─────────────────┐    LayerZero V2    ┌─────────────────┐
│   Source Chain  │ ───────────────── │   HyperEVM      │
│                 │                    │                 │
│ • UMA CTF       │                    │ • CTFRelayer    │
│   Adapter       │                    │ • Conditional   │
│ • prepareCond.  │                    │   Tokens (CTF)  │
│ • reportPayouts │                    │                 │
└─────────────────┘                    └─────────────────┘
```

### Contract Components

- **CTFRelayer**: Main relayer contract extending LayerZero's OApp
- **ConditionalTokens**: HyperEVM's CTF implementation
- **LayerZero Endpoint V2**: Cross-chain messaging protocol

## Contract Interface

### Core Functions

#### `prepareCondition`
Relays conditional token preparation from source chain to HyperEVM.

```solidity
function prepareCondition(
    uint32 _dstEid,           // Destination endpoint ID (HyperEVM)
    bytes32 _questionId,      // Unique question identifier
    uint8 _outcomeSlotCount,  // Number of outcome slots
    bytes calldata _options   // LayerZero message options
) external payable;
```

#### `reportPayouts`
Relays payout reporting from source chain to HyperEVM.

```solidity
function reportPayouts(
    uint32 _dstEid,           // Destination endpoint ID (HyperEVM)
    bytes32 _questionId,      // Question identifier
    uint[] calldata _payouts, // Payout array for each outcome
    bytes calldata _options   // LayerZero message options
) external payable;
```

### Fee Estimation Functions

#### `quotePrepareCondition`
Estimates fees for `prepareCondition` operation.

```solidity
function quotePrepareCondition(
    uint32 _dstEid,
    bytes32 _questionId,
    uint8 _outcomeSlotCount,
    bytes calldata _options,
    bool _payInLzToken
) external view returns (MessagingFee memory fee);
```

#### `quoteReportPayouts`
Estimates fees for `reportPayouts` operation.

```solidity
function quoteReportPayouts(
    uint32 _dstEid,
    bytes32 _questionId,
    uint[] calldata _payouts,
    bytes calldata _options,
    bool _payInLzToken
) external view returns (MessagingFee memory fee);
```

### View Functions

#### `getPrepareConditionFee`
Returns native fee for `prepareCondition`.

```solidity
function getPrepareConditionFee(
    uint32 _dstEid,
    bytes32 _questionId,
    uint8 _outcomeSlotCount,
    bytes calldata _options,
    bool _payInLzToken
) external view returns (uint256 nativeFee);
```

#### `getReportPayoutsFee`
Returns native fee for `reportPayouts`.

```solidity
function getReportPayoutsFee(
    uint32 _dstEid,
    bytes32 _questionId,
    uint[] calldata _payouts,
    bytes calldata _options,
    bool _payInLzToken
) external view returns (uint256 nativeFee);
```

## Frontend Integration

### 1. Contract Setup

First, import the contract ABI and set up the contract instance:

```typescript
import { CTFRelayerABI } from './CTFRelayer.json';

// Contract addresses (update with deployed addresses)
const CONTRACT_ADDRESSES = {
  // HyperEVM testnet
  CTF_RELAYER: '0x...', // Deployed CTFRelayer address
  HYPEREVM_ENDPOINT: '0x...', // LayerZero endpoint on HyperEVM
  CTF: '0x...', // Conditional Tokens Framework on HyperEVM
};

// LayerZero endpoint IDs
const ENDPOINT_IDS = {
  HYPEREVM_TESTNET: 40232, // Update with actual HyperEVM testnet ID
  BASE: 30184, // Base mainnet
  ARBITRUM: 30110, // Arbitrum One
};
```

### 2. Web3 Setup

```typescript
import { ethers } from 'ethers';

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider(RPC_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract instances
const ctfRelayer = new ethers.Contract(
  CONTRACT_ADDRESSES.CTF_RELAYER,
  CTFRelayerABI,
  signer
);
```

### 3. Fee Estimation

Always estimate fees before executing cross-chain operations:

```typescript
async function estimatePrepareConditionFee(
  questionId: string,
  outcomeSlotCount: number,
  options?: string
): Promise<string> {
  try {
    const fee = await ctfRelayer.getPrepareConditionFee(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      outcomeSlotCount,
      options || '0x', // Empty options = default
      false // payInLzToken
    );

    return ethers.formatEther(fee);
  } catch (error) {
    console.error('Fee estimation failed:', error);
    throw error;
  }
}

async function estimateReportPayoutsFee(
  questionId: string,
  payouts: number[],
  options?: string
): Promise<string> {
  try {
    const fee = await ctfRelayer.getReportPayoutsFee(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      payouts,
      options || '0x', // Empty options = default
      false // payInLzToken
    );

    return ethers.formatEther(fee);
  } catch (error) {
    console.error('Fee estimation failed:', error);
    throw error;
  }
}
```

### 4. Prepare Condition

Execute conditional token preparation:

```typescript
async function prepareCondition(
  questionId: string,
  outcomeSlotCount: number,
  options?: string
): Promise<string> {
  try {
    // Estimate fee first
    const feeEstimate = await estimatePrepareConditionFee(
      questionId,
      outcomeSlotCount,
      options
    );

    console.log(`Estimated fee: ${feeEstimate} ETH`);

    // Execute transaction
    const tx = await ctfRelayer.prepareCondition(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      outcomeSlotCount,
      options || '0x', // Empty options = default
      {
        value: ethers.parseEther(feeEstimate),
        gasLimit: 500000
      }
    );

    console.log('Transaction sent:', tx.hash);
    await tx.wait();

    return tx.hash;
  } catch (error) {
    console.error('Prepare condition failed:', error);
    throw error;
  }
}
```

### 5. Report Payouts

Execute payout reporting:

```typescript
async function reportPayouts(
  questionId: string,
  payouts: number[],
  options?: string
): Promise<string> {
  try {
    // Estimate fee first
    const feeEstimate = await estimateReportPayoutsFee(
      questionId,
      payouts,
      options
    );

    console.log(`Estimated fee: ${feeEstimate} ETH`);

    // Execute transaction
    const tx = await ctfRelayer.reportPayouts(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      payouts,
      options || '0x', // Empty options = default
      {
        value: ethers.parseEther(feeEstimate),
        gasLimit: 500000
      }
    );

    console.log('Transaction sent:', tx.hash);
    await tx.wait();

    return tx.hash;
  } catch (error) {
    console.error('Report payouts failed:', error);
    throw error;
  }
}
```

### 6. LayerZero Options

Customize LayerZero message options for advanced use cases:

```typescript
import { Options } from '@layerzerolabs/lz-v2-utilities';

// Create custom options with higher gas limit
function createCustomOptions(): string {
  const options = Options.newOptions()
    .addExecutorLzReceiveOption(500000, 0) // 500k gas, 0 native value
    .toBytes();

  return options;
}

// Use custom options
await prepareCondition(
  questionId,
  outcomeSlotCount,
  createCustomOptions()
);
```

### 7. Event Monitoring

Listen for cross-chain operation events:

```typescript
// Listen for prepare condition events
ctfRelayer.on('PrepareConditionSent', (
  dstEid: number,
  questionId: string,
  outcomeSlotCount: number,
  event: any
) => {
  console.log('Prepare condition sent:', {
    dstEid,
    questionId,
    outcomeSlotCount,
    txHash: event.transactionHash
  });
});

// Listen for report payouts events
ctfRelayer.on('ReportPayoutsSent', (
  dstEid: number,
  questionId: string,
  payouts: number[],
  event: any
) => {
  console.log('Report payouts sent:', {
    dstEid,
    questionId,
    payouts,
    txHash: event.transactionHash
  });
});
```

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# Network Configuration
HYPEREVM_TESTNET_RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm
BASE_RPC_URL=https://mainnet.base.org
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc

# Contract Addresses
HYPEREVM_TESTNET_ENDPOINT_V2=0x...
CTF_RELAYER_ADDRESS=0x...
CTF_ADDRESS=0x...

# Account
DEPLOYER_PK_HYPEREVM=your_private_key_here
DEPLOYER_HYPEREVM=your_address_here

# LayerZero Configuration
LZ_ENDPOINT_ID_HYPEREVM=40232
LZ_ENDPOINT_ID_BASE=30184
```

### Network Configuration

```typescript
const NETWORK_CONFIG = {
  hyperEVM: {
    chainId: 999, // Update with actual HyperEVM chain ID
    rpcUrl: process.env.HYPEREVM_TESTNET_RPC_URL!,
    endpointId: 40232,
    contracts: {
      ctfRelayer: process.env.CTF_RELAYER_ADDRESS!,
      ctf: process.env.CTF_ADDRESS!,
      endpoint: process.env.HYPEREVM_TESTNET_ENDPOINT_V2!
    }
  },
  base: {
    chainId: 8453,
    rpcUrl: process.env.BASE_RPC_URL!,
    endpointId: 30184,
    contracts: {
      // Base chain contracts if needed
    }
  }
};
```

## Usage Examples

### Complete Integration Example

```typescript
class CTFRelayerService {
  private ctfRelayer: ethers.Contract;
  private provider: ethers.JsonRpcProvider;
  private signer: ethers.Wallet;

  constructor(rpcUrl: string, privateKey: string, contractAddress: string) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.signer = new ethers.Wallet(privateKey, this.provider);
    this.ctfRelayer = new ethers.Contract(
      contractAddress,
      CTFRelayerABI,
      this.signer
    );
  }

  // Initialize a prediction market
  async initializeMarket(
    questionId: string,
    outcomeCount: number
  ): Promise<string> {
    console.log('Initializing market:', { questionId, outcomeCount });

    try {
      // 1. Estimate fee
      const fee = await this.estimatePrepareConditionFee(questionId, outcomeCount);

      // 2. Execute preparation
      const tx = await this.ctfRelayer.prepareCondition(
        ENDPOINT_IDS.HYPEREVM_TESTNET,
        questionId,
        outcomeCount,
        '0x', // Default options
        { value: ethers.parseEther(fee) }
      );

      await tx.wait();
      console.log('Market initialized:', tx.hash);
      return tx.hash;
    } catch (error) {
      console.error('Market initialization failed:', error);
      throw error;
    }
  }

  // Resolve a prediction market
  async resolveMarket(
    questionId: string,
    payouts: number[]
  ): Promise<string> {
    console.log('Resolving market:', { questionId, payouts });

    try {
      // 1. Estimate fee
      const fee = await this.estimateReportPayoutsFee(questionId, payouts);

      // 2. Execute resolution
      const tx = await this.ctfRelayer.reportPayouts(
        ENDPOINT_IDS.HYPEREVM_TESTNET,
        questionId,
        payouts,
        '0x', // Default options
        { value: ethers.parseEther(fee) }
      );

      await tx.wait();
      console.log('Market resolved:', tx.hash);
      return tx.hash;
    } catch (error) {
      console.error('Market resolution failed:', error);
      throw error;
    }
  }

  // Helper methods
  private async estimatePrepareConditionFee(
    questionId: string,
    outcomeCount: number
  ): Promise<string> {
    const fee = await this.ctfRelayer.getPrepareConditionFee(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      outcomeCount,
      '0x',
      false
    );
    return ethers.formatEther(fee);
  }

  private async estimateReportPayoutsFee(
    questionId: string,
    payouts: number[]
  ): Promise<string> {
    const fee = await this.ctfRelayer.getReportPayoutsFee(
      ENDPOINT_IDS.HYPEREVM_TESTNET,
      questionId,
      payouts,
      '0x',
      false
    );
    return ethers.formatEther(fee);
  }
}

// Usage
const service = new CTFRelayerService(
  process.env.HYPEREVM_TESTNET_RPC_URL!,
  process.env.DEPLOYER_PK_HYPEREVM!,
  process.env.CTF_RELAYER_ADDRESS!
);

// Initialize a binary market
await service.initializeMarket(
  '0x123...', // Question ID
  2 // Binary outcome (Yes/No)
);

// Resolve the market
await service.resolveMarket(
  '0x123...', // Question ID
  [1, 0] // Yes=1, No=0 (Yes wins)
);
```

## Deployment

### Prerequisites

1. **Foundry**: Install Foundry toolchain
2. **Environment Setup**: Configure `.env` file with required variables
3. **Network Access**: Ensure access to target networks

### Deploy to HyperEVM

```bash
# Set environment variables
export DEPLOYER_PK_HYPEREVM=your_private_key
export HYPEREVM_TESTNET_ENDPOINT_V2=0x...
export DEPLOYER_HYPEREVM=your_address
export CTF=0x... # CTF address on HyperEVM

# Deploy contract
forge script script/deployCTFRelayerOnHyperEVM.s.sol \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  --private-key $DEPLOYER_PK_HYPEREVM \
  --broadcast
```

### Verify Deployment

```bash
# Check contract deployment
cast call $CTF_RELAYER_ADDRESS "owner()" --rpc-url $HYPEREVM_TESTNET_RPC_URL

# Verify CTF address
cast call $CTF_RELAYER_ADDRESS "CTF()" --rpc-url $HYPEREVM_TESTNET_RPC_URL
```

## Security Considerations

### 1. Access Control
- Only contract owner can set peers and enforced options
- Verify owner address before integration

### 2. Fee Management
- Always estimate fees before transactions
- Implement proper error handling for insufficient fees
- Consider fee buffer for network congestion

### 3. Input Validation
- Validate question IDs and payout arrays
- Ensure outcome slot counts are reasonable
- Sanitize LayerZero options

### 4. Event Monitoring
- Monitor `PrepareConditionSent` and `ReportPayoutsSent` events
- Implement retry logic for failed cross-chain messages
- Track transaction confirmations

### 5. Network Configuration
- Use appropriate gas limits for cross-chain operations
- Monitor LayerZero endpoint versions
- Keep endpoint IDs updated

## Error Handling

### Common Errors

```typescript
const ERROR_MESSAGES = {
  'LzTokenUnavailable': 'LayerZero token unavailable',
  'NoPeer': 'No peer configured for endpoint',
  'NotEnoughNative': 'Insufficient native token for fees',
  'OnlyEndpoint': 'Only LayerZero endpoint can call',
  'OnlyPeer': 'Only configured peer can send messages'
};

function handleError(error: any): string {
  const message = error.message || error.toString();

  for (const [errorType, userMessage] of Object.entries(ERROR_MESSAGES)) {
    if (message.includes(errorType)) {
      return userMessage;
    }
  }

  return 'Transaction failed. Please try again.';
}
```
