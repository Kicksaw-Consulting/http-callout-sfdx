@isTest
public without sharing class BatchIntegrationExecutionRetryTest {
  @TestSetup
  static void makeData() {
    KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
      Name = 'Test Integration',
      Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper',
      Enable_Retry__c = true,
      Maximum_Retries__c = 3,
      Retry_Interval__c = 15,
      Status_Codes_to_Retry__c = '400,500'
    );

    insert integration;

    KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Next_Retry_Scheduled__c = Datetime.now(),
      Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM'
    );

    insert execution;

    KicksawEng__IntegrationLog__c log = new KicksawEng__IntegrationLog__c(
      KicksawEng__IntegrationExecution__c = execution.Id,
      KicksawEng__StatusCode__c = 500
    );
    insert log;
  }

  @isTest
  public static void testRetry() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'Success',
      '{"success": true}',
      null
    );

    Test.setMock(HttpCalloutMock.class, mockCallout);
    Test.startTest();

    BatchIntegrationExecutionRetry retryBatch = new BatchIntegrationExecutionRetry();
    Database.executeBatch(retryBatch, 100);
    Test.stopTest();
  }

  @isTest
  public static void schedulableTest() {
    Test.startTest();
    BatchIntegrationExecutionRetry retryBatch = new BatchIntegrationExecutionRetry();
    String jobId = System.schedule(
      'BatchIntegrationExecutionRetry',
      '0 0 0 15 3 ?',
      retryBatch
    );
    Test.stopTest();

    //Check that job has been scheduled
    System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
  }
}
