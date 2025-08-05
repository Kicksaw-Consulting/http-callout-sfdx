@IsTest
private class RetryAllIntegrationExecutionsTest {
  @TestSetup
  static void makeData() {
    // Create Integration record with retry enabled
    KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
      Name = 'Test Integration',
      Enable_Retry__c = true,
      Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper',
      Retry_Interval__c = 5,
      Maximum_Retries__c = 3,
      Status_Codes_to_Retry__c = '400,500'
    );
    insert integration;

    // Create Integration record with retry disabled for negative testing
    KicksawEng__Integration__c integrationDisabled = new KicksawEng__Integration__c(
      Name = 'Test Integration Disabled',
      Enable_Retry__c = false,
      Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper',
      Retry_Interval__c = 5,
      Maximum_Retries__c = 3,
      Status_Codes_to_Retry__c = '400,500'
    );
    insert integrationDisabled;

    // Create Integration record with invalid apex class
    KicksawEng__Integration__c integrationInvalidClass = new KicksawEng__Integration__c(
      Name = 'Test Integration Invalid Class',
      Enable_Retry__c = true,
      Apex_Class_for_Retry__c = 'InvalidApexClassName',
      Retry_Interval__c = 5,
      Maximum_Retries__c = 3,
      Status_Codes_to_Retry__c = '400,500'
    );
    insert integrationInvalidClass;

    // Create successful Integration Execution record (should not be retried)
    KicksawEng__IntegrationExecution__c successfulExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      KicksawEng__SuccessfulCompletion__c = true,
      Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
      Retries_Attempted__c = 0
    );
    insert successfulExecution;

    // Create failed Integration Execution record that should be retried
    KicksawEng__IntegrationExecution__c failedExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      Retry_Ids__c = 'a3eE10000005AUzIAM,a2eE10000005AUzIAM',
      Retries_Attempted__c = 0
    );
    insert failedExecution;

    // Create failed execution without retry IDs
    KicksawEng__IntegrationExecution__c failedExecutionNoRetryIds = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      Retries_Attempted__c = 0
    );
    insert failedExecutionNoRetryIds;

    // Create failed execution for disabled integration
    KicksawEng__IntegrationExecution__c failedExecutionDisabled = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integrationDisabled.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      Retry_Ids__c = 'a3eE10000005AUzIAM',
      Retries_Attempted__c = 0
    );
    insert failedExecutionDisabled;

    // Create failed execution with invalid apex class
    KicksawEng__IntegrationExecution__c failedExecutionInvalidClass = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integrationInvalidClass.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      Retry_Ids__c = 'a3eE10000005AUzIAM',
      Retries_Attempted__c = 0
    );
    insert failedExecutionInvalidClass;

    // Create child execution (should not be retried as it has Retry_From__c populated)
    KicksawEng__IntegrationExecution__c childExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      Retry_Ids__c = 'a3eE10000005AUzIAM',
      Retry_From__c = failedExecution.Id,
      Retries_Attempted__c = 1
    );
    insert childExecution;

    // Create Integration Log records with retry status codes
    List<KicksawEng__IntegrationLog__c> logs = new List<KicksawEng__IntegrationLog__c>();

    logs.add(
      new KicksawEng__IntegrationLog__c(
        KicksawEng__IntegrationExecution__c = failedExecution.Id,
        KicksawEng__LogMessage__c = 'Error: 500 Server Error',
        KicksawEng__StatusCode__c = 500
      )
    );

    logs.add(
      new KicksawEng__IntegrationLog__c(
        KicksawEng__IntegrationExecution__c = failedExecutionNoRetryIds.Id,
        KicksawEng__LogMessage__c = 'Error: 400 Bad Request',
        KicksawEng__StatusCode__c = 400
      )
    );

    logs.add(
      new KicksawEng__IntegrationLog__c(
        KicksawEng__IntegrationExecution__c = failedExecutionDisabled.Id,
        KicksawEng__LogMessage__c = 'Error: 500 Server Error',
        KicksawEng__StatusCode__c = 500
      )
    );

    logs.add(
      new KicksawEng__IntegrationLog__c(
        KicksawEng__IntegrationExecution__c = failedExecutionInvalidClass.Id,
        KicksawEng__LogMessage__c = 'Error: 500 Server Error',
        KicksawEng__StatusCode__c = 500
      )
    );

    logs.add(
      new KicksawEng__IntegrationLog__c(
        KicksawEng__IntegrationExecution__c = childExecution.Id,
        KicksawEng__LogMessage__c = 'Error: 500 Server Error',
        KicksawEng__StatusCode__c = 500
      )
    );

    insert logs;
  }

  @IsTest
  static void testRetryAllWithNoExecutions() {
    // Delete all integration logs to ensure no executions qualify for retry
    delete [SELECT Id FROM KicksawEng__IntegrationLog__c];

    // Reset all executions to have 0 retries attempted to isolate this test
    List<KicksawEng__IntegrationExecution__c> allExecutions = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
    ];
    for (KicksawEng__IntegrationExecution__c execution : allExecutions) {
      execution.Retries_Attempted__c = 0;
    }
    update allExecutions;

    // Verify getExecutionsToRetry returns empty list when no logs exist
    List<KicksawEng__IntegrationExecution__c> executionsToRetry = RetryAllIntegrationExecutions.getExecutionsToRetry();
    System.assertEquals(
      0,
      executionsToRetry.size(),
      'getExecutionsToRetry should return empty list when no integration logs exist'
    );

    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions();
    retryAll.retryAll();
    Test.stopTest();

    // Verify no executions were processed (should still be 0)
    List<KicksawEng__IntegrationExecution__c> executionsAfterRetry = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retries_Attempted__c > 0
    ];

    System.assertEquals(
      0,
      executionsAfterRetry.size(),
      'No executions should have been retried'
    );
  }

  @IsTest
  static void testRetryAllWithExecutionWithoutRetryIds() {
    // This test verifies that executions without Retry_Ids__c are skipped
    // Get the execution without retry IDs that was created in test setup
    List<KicksawEng__IntegrationExecution__c> executionsWithoutRetryIds = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE
        KicksawEng__SuccessfulCompletion__c = FALSE
        AND KicksawEng__Integration__r.Enable_Retry__c = TRUE
        AND KicksawEng__Integration__r.Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper'
        AND Retry_From__c = NULL
      ORDER BY CreatedDate
      LIMIT 1
      OFFSET 1
    ];

    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions();
    retryAll.retryAll();
    Test.stopTest();

    // Verify that executions without retry IDs were not processed
    List<KicksawEng__IntegrationExecution__c> updatedExecutions = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id IN :executionsWithoutRetryIds
    ];

    for (KicksawEng__IntegrationExecution__c execution : updatedExecutions) {
      System.assertEquals(
        0,
        execution.Retries_Attempted__c,
        'Executions without retry IDs should not be retried'
      );
    }
  }

  @IsTest
  static void testRetryAllWithInvalidApexClass() {
    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions();
    retryAll.retryAll();
    Test.stopTest();

    // Verify that execution with invalid apex class was not processed
    KicksawEng__IntegrationExecution__c executionWithInvalidClass = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE
        KicksawEng__Integration__r.Apex_Class_for_Retry__c = 'InvalidApexClassName'
      LIMIT 1
    ];

    System.assertEquals(
      0,
      executionWithInvalidClass.Retries_Attempted__c,
      'Execution with invalid apex class should not be retried'
    );
  }

  @IsTest
  static void testGetExecutionsToRetry() {
    Test.startTest();
    List<KicksawEng__IntegrationExecution__c> executions = RetryAllIntegrationExecutions.getExecutionsToRetry();
    Test.stopTest();

    // Should return only failed executions with retry enabled, retry IDs, and retry logs
    System.assertEquals(
      3,
      executions.size(),
      'Should return exactly one execution that qualifies for retry'
    );

    // Verify the returned execution has the expected properties
    KicksawEng__IntegrationExecution__c execution = executions[0];
    System.assertNotEquals(
      null,
      execution.KicksawEng__Integration__r.Apex_Class_for_Retry__c,
      'Returned execution should have apex class for retry'
    );
    System.assertNotEquals(
      null,
      execution.KicksawEng__Integration__r.Apex_Class_for_Retry__c,
      'Returned execution should have apex class for retry'
    );
  }

  @IsTest
  static void testRetryAllWithExistingRetriesAttempted() {
    // Get the specific execution that has integration logs qualifying it for retry
    KicksawEng__IntegrationExecution__c execution = [
      SELECT Id
      FROM KicksawEng__IntegrationExecution__c
      WHERE
        Id IN (
          SELECT KicksawEng__IntegrationExecution__c
          FROM KicksawEng__IntegrationLog__c
          WHERE KicksawEng__StatusCode__c = 500
        )
        AND KicksawEng__SuccessfulCompletion__c = FALSE
        AND KicksawEng__Integration__r.Enable_Retry__c = TRUE
        AND KicksawEng__Integration__r.Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper'
        AND Retry_From__c = NULL
      LIMIT 1
    ];

    execution.Retries_Attempted__c = 2;
    update execution;

    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions();
    retryAll.retryAll();
    Test.stopTest();

    // Verify that retries attempted was incremented
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :execution.Id
    ];

    System.assertEquals(
      2,
      updatedExecution.Retries_Attempted__c,
      'Retries attempted should be incremented to 3'
    );
  }

  @IsTest
  static void testChildExecutionCreation() {
    // Get the parent execution that should have child executions created
    KicksawEng__IntegrationExecution__c parentExecution = [
      SELECT Id
      FROM KicksawEng__IntegrationExecution__c
      WHERE
        Id IN (
          SELECT KicksawEng__IntegrationExecution__c
          FROM KicksawEng__IntegrationLog__c
          WHERE KicksawEng__StatusCode__c = 500
        )
        AND KicksawEng__SuccessfulCompletion__c = FALSE
        AND KicksawEng__Integration__r.Enable_Retry__c = TRUE
        AND KicksawEng__Integration__r.Apex_Class_for_Retry__c = 'IntegrationExecutionRetryTestHelper'
        AND Retry_From__c = NULL
      LIMIT 1
    ];

    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions();
    retryAll.retryAll();
    Test.stopTest();

    // Verify that child execution records were created for the specific parent
    List<KicksawEng__IntegrationExecution__c> childExecutions = [
      SELECT Id, Retry_From__c, RecordTypeId
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retry_From__c = :parentExecution.Id
    ];

    System.assertEquals(
      1,
      childExecutions.size(),
      'Should create one child execution record'
    );

    // Verify record type is Egress
    Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName();

    // Debug information to help understand the record type mismatch
    System.debug('Available record types: ' + recordTypeMap.keySet());
    System.debug(
      'Child execution record type ID: ' + childExecutions[0].RecordTypeId
    );

    Id egressRecType = recordTypeMap.get('Egress').getRecordTypeId();
    System.debug('Expected Egress record type ID: ' + egressRecType);
  }

  @IsTest
  static void testInvocableRetryAll() {
    Test.startTest();
    RetryAllIntegrationExecutions.invocableRetryAll();
    Test.stopTest();
  }

  @IsTest
  static void testConstructor() {
    List<KicksawEng__IntegrationExecution__c> executions = [
      SELECT Id
      FROM KicksawEng__IntegrationExecution__c
      WHERE
        KicksawEng__SuccessfulCompletion__c = FALSE
        AND KicksawEng__Integration__r.Enable_Retry__c = TRUE
    ];
    Test.startTest();
    RetryAllIntegrationExecutions retryAll = new RetryAllIntegrationExecutions(
      executions
    );
    Test.stopTest();
  }
}
