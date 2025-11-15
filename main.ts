import * as dotenv from 'dotenv';
import { createClient, decodeReport, LogLevel } from '@chainlink/data-streams-sdk';

dotenv.config();

// Basic .env checker
const requireEnv = (key: string): string => {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
};


// Create client using sdk or any WSS client
const client = createClient({
  apiKey: requireEnv('DATASTREAMS_API_KEY'),
  userSecret: requireEnv('DATASTREAMS_API_SECRET'),
  endpoint: requireEnv('DATASTREAMS_REST_URL'),
  wsEndpoint: requireEnv('DATASTREAMS_WS_URL'),
  // Comment to disable SDK logging for debugging:
  logging: {
    logger: console,
    logLevel: LogLevel.INFO
  }
});

const feedId = requireEnv('DATASTREAMS_FEED_ID');
const feedName = process.env.DATASTREAMS_FEED_NAME;
const stream = client.createStream([feedId]);

stream.on('report', (report) => {
  console.log('\n==============================');
  console.log('📡 New Data Streams report');
  console.log(
    `Feed: ${feedName ? `${feedName} (${report.feedID})` : report.feedID}`
  );
  console.log(`Raw blob length: ${report.fullReport.length} chars`);

  try {
    const decoded = decodeReport(report.fullReport, report.feedID);
    const decodedAny = decoded as unknown as Record<string, unknown>;
    const priceRawCandidates = [
      decodedAny['price'],
      decodedAny['benchmarkPrice'],
      decodedAny['nativeBenchmarkPrice'],
      decodedAny['midPrice'],
      decodedAny['exchangeRate'],
      decodedAny['navPerShare'],
      decodedAny['tokenizedPrice'],
      (decodedAny['payload'] as Record<string, unknown> | undefined)?.[
        'benchmarkPrice'
      ],
    ];
    const priceRaw = priceRawCandidates.find(
      (value) => typeof value !== 'undefined'
    );

    const priceFormatted =
      typeof priceRaw !== 'undefined'
        ? Number(priceRaw) / 1e18
        : undefined;

    console.log('Decoded fields (payload only):');
    console.dir(
      {
        version: decoded.version,
        ...decodedAny,
      },
      { depth: null }
    );

    console.log('Human-readable summary:');
    console.log({
      observationsTimestamp: new Date(
        Number(report.observationsTimestamp) * 1000
      ).toISOString(),
      validFromTimestamp: new Date(
        Number(report.validFromTimestamp) * 1000
      ).toISOString(),
      marketStatus:
        typeof decodedAny['marketStatus'] !== 'undefined'
          ? decodedAny['marketStatus']
          : 'n/a',
      price:
        typeof priceFormatted === 'number'
          ? `$${priceFormatted.toFixed(2)}`
          : priceRaw ?? 'n/a',
    });

  } catch (err) {
    console.error('Failed to decode report:', err);
  }
});

stream.on('error', (error) => {
  console.error('Stream error:', error);
});

console.log('Connecting to Data Streams...');
await stream.connect();
console.log('✅ Connected. Listening for reports...');
