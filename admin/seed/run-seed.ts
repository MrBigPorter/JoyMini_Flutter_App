import { loadEnvForHost } from '../utils/load-env-for-host';

// Must run before importing seed modules that instantiate PrismaClient.
loadEnvForHost();

void import('./index');
