public without sharing abstract class RetryIntegrationAbstractQueuable implements Queueable, Database.AllowsCallouts {
  protected KicksawEng__IntegrationExecution__c execution;
  protected Set<Id> recordIds;
  protected KicksawEng__IntegrationExecution__c retryParentExecution;

  public void initializeVarRetry(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds,
    KicksawEng__IntegrationExecution__c retryParentExecution
  ) {
    this.execution = execution;
    this.recordIds = recordIds;
    this.retryParentExecution = retryParentExecution;
  }

  public void initializeVar(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds
  ) {
    this.initializeVarRetry(execution, recordIds, null);
  }

  // Implementing the execute method of the Queueable interface
  public void execute(QueueableContext context) {
    // This method will be implemented by concrete subclasses
    processRecords();
  }

  public abstract void initRetry(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds,
    KicksawEng__IntegrationExecution__c retryParentExecution
  );

  public abstract void init(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds
  );

  // Abstract method to be implemented by concrete subclasses
  protected abstract void processRecords();
}
