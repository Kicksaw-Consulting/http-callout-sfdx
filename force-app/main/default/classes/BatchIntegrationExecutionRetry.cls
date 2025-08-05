//This class is used for schedule retries every 15 minutes
public without sharing class BatchIntegrationExecutionRetry implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
  public Boolean successfullyCompleteAllRetries = true;

  public void execute(SchedulableContext SC) {
    Database.executeBatch(
      new BatchIntegrationExecutionRetry(),
      Integer.valueOf(System.Label.Integration_Execution_Retry_Batch_Size)
    );
  }
  public Database.QueryLocator start(Database.BatchableContext BC) {
    Datetime minutes15Ago = Datetime.now().addMinutes(-15);
    Datetime now = Datetime.now();
    system.debug('now: ' + now);
    system.debug('minutes15Ago: ' + minutes15Ago);
    String query =
      'SELECT Id, KicksawEng__Integration__r.Apex_Class_for_Retry__c, Retry_Ids__c, KicksawEng__Integration__r.Retry_Interval__c, KicksawEng__Integration__r.Maximum_Retries__c, Retries_Attempted__c ' +
      'FROM KicksawEng__IntegrationExecution__c ' +
      'WHERE (Id IN (SELECT KicksawEng__IntegrationExecution__c FROM KicksawEng__IntegrationLog__c WHERE Status_Code_in_Retry_List__c = true)) ' +
      'AND (Max_Retries_Reached__c = false) ' +
      'AND (Retry_From__c = null) ' + //indicates this is original execution
      'AND (Next_Retry_Scheduled__c<=:now) ' +
      'AND (Next_Retry_Scheduled__c >= :minutes15Ago) ' +
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
      List<Retry_Process__e> retryEvents = separateEventIntoBatches(
        executionIdsToRetry
      );
      for (Retry_Process__e retryEvent : retryEvents) {
        EventBus.publish(retryEvent);
      }
    }
  }

  public void finish(Database.BatchableContext BC) {
  }

  public static List<Retry_Process__e> separateEventIntoBatches(
    List<String> executionIds
  ) {
    List<Retry_Process__e> retryEvents = new List<Retry_Process__e>();
    Integer batchSize = 13;

    for (Integer i = 0; i < executionIds.size(); i += batchSize) {
      List<String> batchIds = new List<String>();
      Integer endIndex = Math.min(i + batchSize, executionIds.size());

      for (Integer j = i; j < endIndex; j++) {
        batchIds.add(executionIds[j]);
      }

      String joinedIds = String.join(batchIds, ',');
      Retry_Process__e retryEvent = new Retry_Process__e(
        Execution_Ids_Short_Text__c = joinedIds
      );
      retryEvents.add(retryEvent);
    }

    return retryEvents;
  }
}
