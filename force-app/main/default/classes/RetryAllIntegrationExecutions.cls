public without sharing class RetryAllIntegrationExecutions implements Queueable, Database.AllowsCallouts {
  private List<KicksawEng__IntegrationExecution__c> executions;

  public RetryAllIntegrationExecutions(
    List<KicksawEng__IntegrationExecution__c> executions
  ) {
    this.executions = executions;
  }

  public RetryAllIntegrationExecutions() {
    this.executions = new List<KicksawEng__IntegrationExecution__c>();
  }

  public void execute(QueueableContext context) {
    retryAll();
  }

  public void retryAll() {
    Integer indexWhenLimitReached;
    List<KicksawEng__IntegrationExecution__c> executionsForNextExecution = new List<KicksawEng__IntegrationExecution__c>();

    if (executions.isEmpty()) {
      executions = getExecutionsToRetry(); //This is an initial execution
    }

    for (Integer i = 0; i < executions.size(); i++) {
      if (executions[i].Retry_Ids__c == null) {
        //Retry_Ids__c is a long text area, can't be used in query filters
        continue;
      }

      if (Limits.getQueueableJobs() == Limits.getLimitQueueableJobs() - 1) {
        System.debug('Queueable Jobs Completed: ' + Limits.getQueueableJobs());
        System.debug('Queueable Jobs Limit: ' + Limits.getLimitQueueableJobs());
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
        Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c.getRecordTypeInfosByName()
          .get('Egress')
          .getRecordTypeId();
        KicksawEng__IntegrationExecution__c childExecution = new KicksawEng__IntegrationExecution__c(
          Retry_From__c = executions[i].Id,
          KicksawEng__Integration__c = executions[i].KicksawEng__Integration__c,
          RecordTypeId = egressRecType
        );
        executions[i].Retries_Attempted__c = executions[i]
            .Retries_Attempted__c == null
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
      for (Integer i = indexWhenLimitReached; i < executions.size(); i++) {
        executionsForNextExecution.add(executions[i]);
      }
      RetryAllIntegrationExecutions retryAllIntegrationExecutions = new RetryAllIntegrationExecutions(
        executionsForNextExecution
      );
      System.enqueueJob(retryAllIntegrationExecutions);
    }
  }

  public static List<KicksawEng__IntegrationExecution__c> getExecutionsToRetry() {
    String query =
      'SELECT Id, KicksawEng__Integration__r.Apex_Class_for_Retry__c, Retry_Ids__c, KicksawEng__Integration__r.Retry_Interval__c, KicksawEng__Integration__r.Maximum_Retries__c, Retries_Attempted__c ' +
      'FROM KicksawEng__IntegrationExecution__c ' +
      'WHERE (Id IN (SELECT KicksawEng__IntegrationExecution__c FROM KicksawEng__IntegrationLog__c WHERE Status_Code_in_Retry_List__c = true)) ' +
      'AND (Retry_From__c = null) ' + //indicates this is original execution
      'AND (KicksawEng__Integration__r.Enable_Retry__c = true) ' +
      'AND (KicksawEng__SuccessfulCompletion__c = false)';

    List<KicksawEng__IntegrationExecution__c> executions = Database.query(
      query
    );
    return executions;
  }

  @InvocableMethod(
    label='Integration Execution Retry All-Non-Batch'
    description='Queries for all Integration Executions that need to be retried and enqueues a retry job'
  )
  public static void invocableRetryAll() {
    RetryAllIntegrationExecutions retryAllIntegrationExecutions = new RetryAllIntegrationExecutions();
    retryAllIntegrationExecutions.retryAll(); //synchronous jobs can enqueue 50 jobs
  }
}
