@isTest
public class QueueablePostRetryProcessingTest {
  @TestSetup
  static void setupTestData() {
    // Create Integration record with retry settings
    KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
      Name = 'Test Integration',
      Maximum_Retries__c = 3,
      Retry_Interval__c = 15
    );
    insert integration;
  }

  @isTest
  static void testProcessWithRemainingRetries() {
    KicksawEng__Integration__c integration = [
      SELECT Id, Maximum_Retries__c, Retry_Interval__c
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    // Create parent execution record with retry attempt count
    KicksawEng__IntegrationExecution__c parentExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Retries_Attempted__c = 1
    );
    insert parentExecution;

    // Query the execution record with the Integration relationship
    parentExecution = [
      SELECT
        Id,
        Retries_Attempted__c,
        KicksawEng__Integration__r.Maximum_Retries__c,
        KicksawEng__Integration__r.Retry_Interval__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :parentExecution.Id
    ];

    // Create some test accounts to use their IDs
    List<Account> testAccounts = new List<Account>();
    for (Integer i = 0; i < 2; i++) {
      testAccounts.add(new Account(Name = 'Test Account ' + i));
    }
    insert testAccounts;

    Set<Id> failedIds = new Set<Id>();
    for (Account acc : testAccounts) {
      failedIds.add(acc.Id);
    }

    Test.startTest();

    // Create and enqueue the post-processing job
    QueueablePostRetryProcessing postProcess = new QueueablePostRetryProcessing(
      parentExecution,
      failedIds
    );
    System.enqueueJob(postProcess);

    Test.stopTest();

    // Verify results
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Next_Retry_Scheduled__c, Retry_Ids__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :parentExecution.Id
    ];

    // Verify failed IDs were stored
    System.assertEquals(
      String.join(new List<Id>(failedIds), ','),
      updatedExecution.Retry_Ids__c,
      'Failed record IDs should be stored in comma-separated format'
    );
  }

  @isTest
  static void testProcessWithNoRemainingRetries() {
    KicksawEng__Integration__c integration = [
      SELECT Id, Maximum_Retries__c, Retry_Interval__c
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    // Create parent execution record with max retry attempts
    KicksawEng__IntegrationExecution__c parentExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Retries_Attempted__c = 3
    );
    insert parentExecution;

    // Create a test account to use its ID
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    Set<Id> failedIds = new Set<Id>{ testAccount.Id };

    Test.startTest();

    // Create and enqueue the post-processing job
    QueueablePostRetryProcessing postProcess = new QueueablePostRetryProcessing(
      parentExecution,
      failedIds
    );
    System.enqueueJob(postProcess);

    Test.stopTest();

    // Verify results
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Next_Retry_Scheduled__c, Retry_Ids__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :parentExecution.Id
    ];

    // Verify next retry time was not set
    System.assertEquals(
      null,
      updatedExecution.Next_Retry_Scheduled__c,
      'Next retry time should not be set when max retries reached'
    );

    // Verify failed IDs were still stored
    System.assertEquals(
      String.join(new List<Id>(failedIds), ','),
      updatedExecution.Retry_Ids__c,
      'Failed record IDs should be stored in comma-separated format'
    );
  }
}
