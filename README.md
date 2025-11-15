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

