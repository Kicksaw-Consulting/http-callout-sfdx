public with sharing class RetrySingleIntegrationExecution {
  @InvocableMethod(
    label='Integration Execution Retry Single Integration Execution'
    description='This should be used on the Integration Execution record to retry the execution'
  )
  public static void retrySingleExecution(List<Id> executionIds) {
    KicksawEng__IntegrationExecution__c execution = getExecution(
      executionIds[0]
    );
    Set<Id> retryIds = new Set<Id>();
    List<String> retryIdsStrings = execution.Retry_Ids__c.split(',');

    //Convert the strings to Set of Ids
    for (String retryId : retryIdsStrings) {
      retryIds.add(Id.valueOf(retryId));
    }

    //Create child integration execution records
    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c.getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();
    KicksawEng__IntegrationExecution__c childExecution = new KicksawEng__IntegrationExecution__c(
      Retry_From__c = execution.Id,
      KicksawEng__Integration__c = execution.KicksawEng__Integration__c,
      RecordTypeId = egressRecType
    );
    execution.Retries_Attempted__c = execution.Retries_Attempted__c == null
      ? 1
      : execution.Retries_Attempted__c + 1;
    //Retry the records
    try {
      Type apexClassType = Type.forName(
        execution.KicksawEng__Integration__r.Apex_Class_for_Retry__c
      );
      RetryIntegrationAbstractQueuable retryableClass = (RetryIntegrationAbstractQueuable) apexClassType.newInstance();
      retryableClass.initRetry(childExecution, retryIds, execution);
      System.enqueueJob(retryableClass);
    } catch (Exception e) {
      System.debug(
        'Unable to retry ' +
        execution.KicksawEng__Integration__r.Apex_Class_for_Retry__c
      );
      System.debug('Error: ' + e.getMessage());
    }
  }

  public static KicksawEng__IntegrationExecution__c getExecution(
    Id executionId
  ) {
    String query =
      'SELECT Id, KicksawEng__Integration__r.Apex_Class_for_Retry__c, Retry_Ids__c, KicksawEng__Integration__r.Retry_Interval__c, KicksawEng__Integration__r.Maximum_Retries__c, Retries_Attempted__c ' +
      'FROM KicksawEng__IntegrationExecution__c ' +
      'WHERE Id = :executionId';
    KicksawEng__IntegrationExecution__c execution = Database.query(query);
    return execution;
  }
}
