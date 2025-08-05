public with sharing class QueueablePostRetryProcessing implements Queueable {
  public KicksawEng__IntegrationExecution__c retryParentExecution;
  public Set<Id> failedRetryRecordIds;

  public QueueablePostRetryProcessing(
    KicksawEng__IntegrationExecution__c retryParentExecution,
    Set<Id> failedRetryRecordIds
  ) {
    this.retryParentExecution = retryParentExecution;
    this.failedRetryRecordIds = failedRetryRecordIds;
  }

  public void execute(QueueableContext context) {
    if (
      retryParentExecution.Retries_Attempted__c <
      retryParentExecution.KicksawEng__Integration__r.Maximum_Retries__c
    ) {
      retryParentExecution.Next_Retry_Scheduled__c = Datetime.now()
        .addMinutes(
          Integer.valueOf(
            retryParentExecution.KicksawEng__Integration__r.Retry_Interval__c
          )
        );
    }

    //Update the original execution with the retry ids that failed again
    retryParentExecution.Retry_Ids__c = String.join(
      new List<Id>(failedRetryRecordIds),
      ','
    );

    update retryParentExecution;
  }
}
