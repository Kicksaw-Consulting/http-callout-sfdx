Database.executeBatch(
  new BatchIntegrationExecutionRetry(),
  Integer.valueOf(System.Label.Integration_Execution_Retry_Batch_Size)
);
