public without sharing class BatchRetryAllIntegrationExecutions implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query =
      'SELECT Id, KicksawEng__Integration__r.Apex_Class_for_Retry__c, Retry_Ids__c, KicksawEng__Integration__r.Retry_Interval__c, KicksawEng__Integration__r.Maximum_Retries__c, Retries_Attempted__c ' +
      'FROM KicksawEng__IntegrationExecution__c ' +
      'WHERE (Id IN (SELECT KicksawEng__IntegrationExecution__c FROM KicksawEng__IntegrationLog__c WHERE Status_Code_in_Retry_List__c = true)) ' +
      'AND (Retry_From__c = null) ' + //indicates this is original execution
      'AND (KicksawEng__Integration__r.Enable_Retry__c = true) ' +
      'AND (KicksawEng__SuccessfulCompletion__c = false)';

    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext BC,
    List<KicksawEng__IntegrationExecution__c> executions
  ) {
    List<String> executionIdsToRetry = new List<String>();
    for (KicksawEng__IntegrationExecution__c execution : executions) {
      if (execution.Retry_Ids__c != null) {
        executionIdsToRetry.add(execution.Id);
      }
    }

    //The logic for retries is in the Retry Process trigger because Batch classes can only enqueue 1 job at a time

    if (!executionIdsToRetry.isEmpty()) {
      List<Retry_Process__e> retryEvents = BatchIntegrationExecutionRetry.separateEventIntoBatches(
        executionIdsToRetry
      );
      for (Retry_Process__e retryEvent : retryEvents) {
        EventBus.publish(retryEvent);
      }
    }
  }

  public void finish(Database.BatchableContext BC) {
  }

  @InvocableMethod(
    label='Integration Execution Retry All'
    description='Queries for all Integration Executions that need to be retried and enqueues a retry job'
  )
  public static void invocableRetryAll() {
    Database.executeBatch(
      new BatchRetryAllIntegrationExecutions(),
      Integer.valueOf(System.Label.Integration_Execution_Retry_Batch_Size)
    );
  }
}
