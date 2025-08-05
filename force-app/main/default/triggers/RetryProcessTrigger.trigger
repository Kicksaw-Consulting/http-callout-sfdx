trigger RetryProcessTrigger on Retry_Process__e(after insert) {
  Set<String> executionIds = new Set<String>();
  List<KicksawEng__IntegrationExecution__c> executionsToUpdate = new List<KicksawEng__IntegrationExecution__c>();
  Map<String, List<KicksawEng__IntegrationExecution__c>> executionApexMap = new Map<String, List<KicksawEng__IntegrationExecution__c>>();
  Integer indexWhenLimitReached;

  Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c.getRecordTypeInfosByName()
    .get('Egress')
    .getRecordTypeId();

  for (Retry_Process__e event : Trigger.new) {
    if (event.Execution_Ids_Short_Text__c == null) {
      continue;
    }
    executionIds.addAll(event.Execution_Ids_Short_Text__c.split(','));
  }

  List<KicksawEng__IntegrationExecution__c> executions = [
    SELECT
      Id,
      KicksawEng__Integration__r.Apex_Class_for_Retry__c,
      Retry_Ids__c,
      KicksawEng__Integration__r.Retry_Interval__c,
      KicksawEng__Integration__r.Maximum_Retries__c,
      Retries_Attempted__c
    FROM KicksawEng__IntegrationExecution__c
    WHERE Id IN :executionIds
  ];

  for (Integer i = 0; i < executions.size(); i++) {
    if (executions[i].Retry_Ids__c == null) {
      //Retry_Ids__c is a long text area, can't be used in query filters
      continue;
    }

    if (Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()) {
      System.debug('Queueable Jobs limit reached');
      indexWhenLimitReached = i;
      break;
    } else {
      Set<Id> retryIds = new Set<Id>();
      List<String> retryIdsStrings = executions[i].Retry_Ids__c.split(',');

      //Convert the strings to Set of Ids
      for (String retryId : retryIdsStrings) {
        retryIds.add(Id.valueOf(retryId));
      }

      //Create child integration execution records
      KicksawEng__IntegrationExecution__c childExecution = new KicksawEng__IntegrationExecution__c(
        Retry_From__c = executions[i].Id,
        KicksawEng__Integration__c = executions[i].KicksawEng__Integration__c,
        RecordTypeId = egressRecType
      );
      executions[i].Retries_Attempted__c = executions[i].Retries_Attempted__c ==
        null
        ? 1
        : executions[i].Retries_Attempted__c + 1;
      //Retry the records
      try {
        Type apexClassType = Type.forName(
          executions[i].KicksawEng__Integration__r.Apex_Class_for_Retry__c
        );
        RetryIntegrationAbstractQueuable retryableClass = (RetryIntegrationAbstractQueuable) apexClassType.newInstance();
        retryableClass.initRetry(childExecution, retryIds, executions[i]);
        System.enqueueJob(retryableClass);
      } catch (Exception e) {
        System.debug(
          'Unable to retry ' +
          executions[i].KicksawEng__Integration__r.Apex_Class_for_Retry__c
        );
        System.debug('Error: ' + e.getMessage());
        continue;
      }
    }
  }

  //Republish platform event when queueable job limit is reached
  if (indexWhenLimitReached != null) {
    List<String> executionIdsToRetry = new List<String>();
    for (Integer i = indexWhenLimitReached; i < executions.size(); i++) {
      executionIdsToRetry.add(executions[i].Id);
    }

    List<Retry_Process__e> retryEvents = BatchIntegrationExecutionRetry.separateEventIntoBatches(
      executionIdsToRetry
    );
    for (Retry_Process__e retryEvent : retryEvents) {
      EventBus.publish(retryEvent);
    }
  }
}
