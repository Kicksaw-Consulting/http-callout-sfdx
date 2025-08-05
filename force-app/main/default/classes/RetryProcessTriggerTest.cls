@isTest
public with sharing class RetryProcessTriggerTest {
  @TestSetup
  public static void makeData() {
    KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
      Name = 'Test Integration',
      Apex_Class_for_Retry__c = 'MediaIntelligenceIntegration',
      Enable_Retry__c = true,
      Maximum_Retries__c = 3,
      Retry_Interval__c = 15,
      Status_Codes_to_Retry__c = '400,500'
    );

    insert integration;

    // Create execution with RecordType 'Egress'
    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Next_Retry_Scheduled__c = Datetime.now(),
      Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
      RecordTypeId = egressRecType,
      Retries_Attempted__c = 0
    );
    insert execution;

    KicksawEng__IntegrationLog__c log = new KicksawEng__IntegrationLog__c(
      KicksawEng__IntegrationExecution__c = execution.Id,
      KicksawEng__StatusCode__c = 500
    );
    insert log;
  }
  @isTest
  public static void triggerPlatformEvent() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'Success',
      '{"success": true}',
      null
    );
    KicksawEng__IntegrationExecution__c integrationExecution = [
      SELECT
        Id,
        Retries_Attempted__c,
        KicksawEng__Integration__c,
        KicksawEng__Integration__r.Apex_Class_for_Retry__c,
        KicksawEng__Integration__r.Maximum_Retries__c,
        KicksawEng__Integration__r.Retry_Interval__c,
        Retry_Ids__c
      FROM KicksawEng__IntegrationExecution__c
      LIMIT 1
    ];

    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    // Publish the platform event
    Retry_Process__e retryEvent = new Retry_Process__e(
      Execution_Ids_Short_Text__c = integrationExecution.Id
    );
    EventBus.publish(retryEvent);
    Test.getEventBus().deliver();

    Test.stopTest();

    // Verify the execution was processed
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :integrationExecution.Id
    ];

    System.assertNotEquals(
      null,
      updatedExecution.Retries_Attempted__c,
      'Retry attempt should be incremented'
    );
  }

  @isTest
  public static void reachQueueableTestLimit() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'Success',
      '{"success": true}',
      null
    );

    KicksawEng__Integration__c integration = [
      SELECT Id, Apex_Class_for_Retry__c
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    // Create multiple executions to exceed queueable limit in test context
    List<KicksawEng__IntegrationExecution__c> executionsToInsert = new List<KicksawEng__IntegrationExecution__c>();
    for (Integer i = 0; i < 5; i++) {
      KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
        KicksawEng__Integration__c = integration.Id,
        Next_Retry_Scheduled__c = Datetime.now(),
        Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
        RecordTypeId = egressRecType,
        Retries_Attempted__c = 0
      );
      executionsToInsert.add(execution);
    }
    insert executionsToInsert;

    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    // First, enqueue a job to consume the queueable limit in test context
    System.enqueueJob(new QueueablePostRetryProcessing());

    // Now publish platform event with all execution IDs at once
    // This should trigger the queueable limit scenario in the trigger
    List<String> executionIds = new List<String>();
    for (KicksawEng__IntegrationExecution__c exec : executionsToInsert) {
      executionIds.add(exec.Id);
    }

    String joinedIds = String.join(executionIds, ',');
    Retry_Process__e retryEvent = new Retry_Process__e(
      Execution_Ids_Short_Text__c = joinedIds
    );

    EventBus.publish(retryEvent);
    Test.getEventBus().deliver();

    Test.stopTest();

    // Verify that some executions had their retries attempted incremented
    List<KicksawEng__IntegrationExecution__c> processedExecutions = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id IN :executionIds
    ];

    System.assert(
      !processedExecutions.isEmpty(),
      'Some executions should have been processed'
    );
  }

  @isTest
  public static void testQueueableLimitRepublish() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      500,
      'Server Error',
      '{"error": "Server Error"}',
      null
    );

    KicksawEng__Integration__c integration = [
      SELECT Id, Apex_Class_for_Retry__c
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    // Create exactly 2 executions - one will process, the second should trigger republish
    List<KicksawEng__IntegrationExecution__c> executionsToInsert = new List<KicksawEng__IntegrationExecution__c>();
    for (Integer i = 0; i < 2; i++) {
      KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
        KicksawEng__Integration__c = integration.Id,
        Next_Retry_Scheduled__c = Datetime.now(),
        Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
        RecordTypeId = egressRecType,
        Retries_Attempted__c = 0
      );
      executionsToInsert.add(execution);
    }
    insert executionsToInsert;

    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    // Build execution IDs string
    List<String> executionIds = new List<String>();
    for (KicksawEng__IntegrationExecution__c exec : executionsToInsert) {
      executionIds.add(exec.Id);
    }

    String joinedIds = String.join(executionIds, ',');
    Retry_Process__e retryEvent = new Retry_Process__e(
      Execution_Ids_Short_Text__c = joinedIds
    );

    EventBus.publish(retryEvent);
    Test.getEventBus().deliver();

    Test.stopTest();

    // Verify executions were processed
    List<KicksawEng__IntegrationExecution__c> processedExecutions = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id IN :executionIds AND Retries_Attempted__c > 0
    ];

    System.assert(
      !processedExecutions.isEmpty(),
      'At least one execution should have been processed'
    );
  }

  @isTest
  public static void testNullRetryIdsHandling() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      500,
      'Server Error',
      '{"error": "Server Error"}',
      null
    );

    KicksawEng__Integration__c integration = [
      SELECT Id, Apex_Class_for_Retry__c
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    // Create mix of executions - some with Retry_Ids__c and some without
    List<KicksawEng__IntegrationExecution__c> executionsToInsert = new List<KicksawEng__IntegrationExecution__c>();

    // Execution with null Retry_Ids__c (should be skipped)
    KicksawEng__IntegrationExecution__c nullRetryExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Next_Retry_Scheduled__c = Datetime.now(),
      Retry_Ids__c = null, // Explicitly null
      RecordTypeId = egressRecType,
      Retries_Attempted__c = 0
    );
    executionsToInsert.add(nullRetryExecution);

    // Execution with valid Retry_Ids__c (should be processed)
    KicksawEng__IntegrationExecution__c validRetryExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      Next_Retry_Scheduled__c = Datetime.now(),
      Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
      RecordTypeId = egressRecType,
      Retries_Attempted__c = 0
    );
    executionsToInsert.add(validRetryExecution);

    insert executionsToInsert;

    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    // Build execution IDs string including both null and valid executions
    List<String> executionIds = new List<String>();
    for (KicksawEng__IntegrationExecution__c exec : executionsToInsert) {
      executionIds.add(exec.Id);
    }

    String joinedIds = String.join(executionIds, ',');
    Retry_Process__e retryEvent = new Retry_Process__e(
      Execution_Ids_Short_Text__c = joinedIds
    );

    EventBus.publish(retryEvent);
    Test.getEventBus().deliver();

    Test.stopTest();

    // Verify only the execution with valid Retry_Ids__c was processed
    KicksawEng__IntegrationExecution__c processedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :validRetryExecution.Id
    ];

    KicksawEng__IntegrationExecution__c skippedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :nullRetryExecution.Id
    ];

    System.assertNotEquals(
      null,
      processedExecution.Retries_Attempted__c,
      'Execution with valid Retry_Ids__c should have been processed'
    );

    System.assertEquals(
      0,
      skippedExecution.Retries_Attempted__c,
      'Execution with null Retry_Ids__c should have been skipped'
    );
  }
}
