@isTest
public without sharing class IntegrationExecutionRetryTestHelper extends RetryIntegrationAbstractQueuable {
  public override void initRetry(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds,
    KicksawEng__IntegrationExecution__c retryParentExecution
  ) {
    super.initializeVarRetry(execution, recordIds, retryParentExecution);
  }

  public override void init(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds
  ) {
    super.initializeVar(execution, recordIds);
  }

  public override void processRecords() {
    KicksawEng__IntegrationLog__c log = new KicksawEng__IntegrationLog__c();
    Set<Id> failedRecordIds = new Set<Id>{ 'a3eE10000005AUzIAM' };
    List<KicksawEng__IntegrationLog__c> logs = new List<KicksawEng__IntegrationLog__c>();

    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://www.test.com');
    req.setMethod('GET');
    HttpResponse res = new Http().send(req);

    //Create an exception
    try {
      Decimal num = 1 / 0;
    } catch (Exception e) {
      log = KicksawIntegration.createExceptionLogs(e);
      logs.add(log);
    }

    //Process the execution record and logs
    List<KicksawEng__IntegrationExecution__c> executionsToUpsert = new List<KicksawEng__IntegrationExecution__c>();

    if (failedRecordIds.size() > 0) {
      String retryIdsStr = String.join(failedRecordIds, ',');
      execution.Retry_Ids__c = retryIdsStr;
      if (failedRecordIds.size() == 1) {
        execution.Record_Id__c = failedRecordIds.iterator().next();
      }

      if (retryParentExecution != null) {
        retryParentExecution.KicksawEng__SuccessfulCompletion__c = false;
        retryParentExecution.Retries_Attempted__c = 1;
        executionsToUpsert.add(retryParentExecution);
      }
    } else {
      execution.KicksawEng__SuccessfulCompletion__c = true;
      execution.Next_Retry_Scheduled__c = null;
      if (retryParentExecution != null) {
        retryParentExecution.KicksawEng__SuccessfulCompletion__c = true;
        executionsToUpsert.add(retryParentExecution);
      }
    }

    executionsToUpsert.add(execution);
    upsert executionsToUpsert;

    if (logs.size() > 0) {
      for (KicksawEng__IntegrationLog__c eachlog : logs) {
        eachlog.KicksawEng__IntegrationExecution__c = execution.Id;
      }
      insert logs;
    }
  }
}
