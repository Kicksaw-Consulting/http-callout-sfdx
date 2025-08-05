//Run every 15 minutes
BatchIntegrationExecutionRetry scheduler = new BatchIntegrationExecutionRetry();
System.schedule(
  'Integration Execution Retry Batch 1',
  '0 0 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 2',
  '0 15 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 3',
  '0 30 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 4',
  '0 45 * * * ?',
  scheduler
);
