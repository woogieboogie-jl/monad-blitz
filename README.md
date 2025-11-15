# Monad Blitz – Chainlink Data Streams Demo

`monad-blitz` is a minimal TypeScript script that showcases how to stream, decode, and inspect Chainlink Data Streams reports in real time. It is meant to be a quick reference for Monad builders who want to understand what the Data Streams SDK emits before wiring the data into their own apps or on-chain verifiers.

## Prerequisites

- Node.js 18+
- `pnpm` (the repo pins `pnpm@10.11.0` in `package.json`)
- Valid Chainlink Data Streams credentials (key + secret)

## Installation

```bash
pnpm install
```

## Environment Variables

Create a `.env` alongside `main.ts` with at least:

```
DATASTREAMS_API_KEY=...
DATASTREAMS_API_SECRET=...
DATASTREAMS_REST_URL=https://api.testnet-dataengine.chain.link
DATASTREAMS_WS_URL=wss://ws.testnet-dataengine.chain.link
DATASTREAMS_FEED_ID=0x...
# Optional label for nicer logging:
DATASTREAMS_FEED_NAME=AAPL/USD
```

All values are required except `DATASTREAMS_FEED_NAME`. Make sure the REST and WS URLs match the environment where the key pair was issued (testnet vs. mainnet).

## Running the Streamer

Use `ts-node` (installed on demand via `npx`) to execute the script:

```bash
npx ts-node main.ts
```

You should see output similar to:

```
==============================
📡 New Data Streams report
Feed: AAPL/USD (0x0008...)
Raw blob length: 1474 chars
Decoded fields (payload only):
{
  version: 'V8',
  nativeFee: 101690881013248n,
  linkFee: 22838529455636513n,
  expiresAt: 1765761410,
  midPrice: 272320000000000000000n,
  marketStatus: 1
}
Human-readable summary:
{
  observationsTimestamp: '2025-11-15T01:16:50.000Z',
  validFromTimestamp: '2025-11-15T01:16:50.000Z',
  marketStatus: 1,
  price: '$2723.20'
}
```

The script:

1. Streams reports from the Chainlink Data Streams endpoint using `createClient`.
2. Calls `decodeReport` to parse the payload automatically (no custom ABI needed).
3. Logs the raw decoded fields and a simplified summary (timestamps, market status, normalized price).

Use it as a reference for integrating Data Streams into Monad projects or for demonstrating how reports look before submitting them to an on-chain verifier/oracle.

## Next Steps: On-chain Verification

When you’re ready to prove these reports on-chain, follow Chainlink’s official walkthrough for deploying a `ClientReportsVerifier` contract, funding it with LINK, and calling `verifyReport` on an EVM network. The tutorial covers fee handling, supported report schemas, and verifier proxy addresses:

- [Verify report data onchain (EVM)](https://docs.chain.link/data-streams/tutorials/evm-onchain-report-verification)

You can treat this repository as the “off-chain observability” half of that flow: stream and inspect reports with `monad-blitz`, then push the same `report.fullReport` bytes into the verifier contract described in the guide to complete the end-to-end demo.

---

---








## Mock VRF Coordinator (Foundry)

The repo also includes a tiny Foundry workspace (`contracts/`) with `MockVRFCoordinator`, a synchronous stand-in for `VRFCoordinatorV2`. It keeps the exact same `requestRandomWords` signature but fulfills immediately inside the same transaction using blockhash-derived randomness, so no background listener or subscription UI is required.

### Pre-deployed mock coordinator (testnet only)

| Network       | Chain ID | Coordinator Address                             | Notes                            |
| ------------- | -------- | ----------------------------------------------- | -------------------------------- |
| Monad testnet | 10143    | `0x6c657dC4e4823EBCCd2d9DCde3ef5bEb08914b3F`     | Interface validation only (no prod) |

> ⚠️ This contract is for smoke-testing VRF integrations. It has **zero guarantees** and should never be used with mainnet assets or production workloads.

### Build & deploy

```bash
# Install Foundry once
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Compile from repo root
forge build
```

> Align your environment variable names with `.env.example` (e.g., `MONAD_RPC_URL`, `PRIVATE_KEY_EVM`) before running the commands below.

### Usage flow

1. Point your VRF consumer’s constructor at the deployed mock coordinator address (you can use the provided `MockVRFConsumer` under `contracts/src/mocks/` as a template).
2. Call `requestRandomWords` exactly as you would on mainnet (same parameters, no extra setup). The helper consumer exposes `requestRandomness()` which wraps this call and derives a demo-friendly dice roll (`latestDiceRollResult()` returns a number between 1-6 based on the first random word).
3. Inside the same transaction the mock:
   - Emits `RandomWordsRequested`.
   - Derives `numWords` using `blockhash(block.number - 1)` and the `requestId`.
   - Invokes `rawFulfillRandomWords(requestId, randomWords)` on the calling consumer.
   - Emits `RandomWordsFulfilled`.

Because fulfillment is synchronous, your contract’s `fulfillRandomWords` handler runs immediately after the request call, making local development and automated testing straightforward while keeping the production API shape intact.

### Local testbed

1. Install dependencies and compile:
   ```bash
   forge install foundry-rs/forge-std
   forge test
   ```
2. The test suite deploys `MockVRFCoordinator` plus the sample `MockVRFConsumer`, calls `requestRandomness()`, and asserts the consumer receives two blockhash-derived words. Use this as a reference for wiring up your own consumers or for sanity-checking the mock before pointing frontends/scripts at it.

### Monad testnet demo (interface-only, not production)

Use the pre-deployed coordinator above, then deploy just your consumer and exercise the flow. Export `MONAD_RPC_URL` and `PRIVATE_KEY_EVM` as shown in `.env.example` before running anything.

1. **Deploy the consumer PoC (requests 10 words, exposes a dice roll 1–6).**
   ```bash
   export KEY_HASH=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
   export COORD_ADDR=0x6c657dC4e4823EBCCd2d9DCde3ef5bEb08914b3F

   forge create contracts/src/mocks/MockVRFConsumer.sol:MockVRFConsumer \
     --rpc-url $MONAD_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --broadcast \
     --constructor-args $COORD_ADDR $KEY_HASH 1 3 200000 10
   ```

2. **Trigger a randomness request (fulfillment occurs inside this tx).**
   ```bash
   export CONSUMER=<consumer address from step 1>

   cast send $CONSUMER "requestRandomness()" \
     --rpc-url $MONAD_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --broadcast
   ```

3. **Inspect the results (dice roll + raw words).**
   ```bash
   cast call $CONSUMER "latestDiceRollResult()" --rpc-url $MONAD_RPC_URL
   cast call $CONSUMER "lastRandomWords(uint256)" 0 --rpc-url $MONAD_RPC_URL
   ```

Every invocation of `requestRandomness()` returns a fresh dice value (1–6) plus the raw `uint256` words, all while using the exact VRF consumer interface you’ll use on mainnet. Again, keep this mock strictly to dev/test environments.

---

---

## CCIP Native MON Demo (Monad → Sepolia)

Use the boilerplate CCIP contracts under `contracts/src/mocks/` to send a string payload from Monad testnet to Sepolia while paying CCIP fees in native MON. The steps below assume you have `.env` populated with the addresses included in `.env.example`.

1. **Load environment variables.**
   ```bash
   source .env
   ```

2. **Deploy the sender on Monad (pays fees in MON).**
   ```bash
   forge create contracts/src/mocks/MockCCIPSender.sol:Sender \
     --rpc-url $MONAD_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --broadcast \
     --constructor-args $MONAD_ROUTER_ADDR
   export MONAD_SENDER_ADDR=<address returned by forge>
   ```

3. **Fund the sender (optional if you plan to fund inline).**
   ```bash
   cast send $MONAD_SENDER_ADDR \
     --rpc-url $MONAD_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --value 1ether
   ```
   (You can skip this if you will pass `--value` when calling `sendMessage`.)

4. **Deploy the receiver on the destination chain (Sepolia).**
   ```bash
   forge create contracts/src/mocks/MockCCIPReceiver.sol:MockCCIPReceiver \
     --rpc-url $DEST_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --broadcast \
     --constructor-args $DEST_ROUTER_ADDR
   export DEST_RECEIVER_ADDR=<address returned by forge>
   ```

5. **Send a CCIP message, paying fees in native MON.** `sendMessage` is `payable`, so `--value` both funds the contract and lets it forward the exact router quote via `{value: fees}`.
   ```bash
   cast send $MONAD_SENDER_ADDR \
     "sendMessage(uint64,address,string)" \
     $DEST_CHAIN_SELECTOR \
     $DEST_RECEIVER_ADDR \
     "Hello from Monad Blitz" \
     --rpc-url $MONAD_RPC_URL \
     --private-key $PRIVATE_KEY_EVM \
     --value 1ether \
     --gas-limit 500000
   ```

6. **Verify delivery on the destination chain.**
   ```bash
   cast call $DEST_RECEIVER_ADDR \
     "getLastReceivedMessageDetails()(bytes32,string)" \
     --rpc-url $DEST_RPC_URL
   # or inspect `MessageReceived` logs:
   cast logs --rpc-url $DEST_RPC_URL --address $DEST_RECEIVER_ADDR
   ```

This flow mirrors the CCIP “request and receive” cycle documented by Chainlink: the sender requests a cross-chain message (paying MON fees), the router forwards it to Sepolia, and the receiver emits `MessageReceived` once the payload lands.


