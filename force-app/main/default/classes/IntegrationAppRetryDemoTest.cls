@isTest
private class IntegrationAppRetryDemoTest {
  @TestSetup
  static void makeData() {
    // Create test Contact records
    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < 5; i++) {
      contacts.add(
        new Contact(
          FirstName = 'Test',
          LastName = 'Contact' + i,
          Email = 'testcontact' + i + '@test.com'
        )
      );
    }
    insert contacts;

    // Create Integration record
    KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
      Name = 'Integration Demo',
      Enable_Retry__c = true,
      Apex_Class_for_Retry__c = 'IntegrationAppRetryDemo',
      Retry_Interval__c = 5,
      Maximum_Retries__c = 3,
      Status_Codes_to_Retry__c = '400,500,404'
    );
    insert integration;
  }

  @isTest
  static void testProcessRecordsSuccess() {
    // Setup successful mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'OK',
      '{"success": true, "data": {"id": 123}}',
      new Map<String, String>{ 'Content-Type' => 'application/json' }
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    // Get test data
    List<Contact> contacts = [SELECT Id, Name, Email FROM Contact LIMIT 3];
    KicksawEng__Integration__c integration = [
      SELECT Id
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    // Create execution record
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    Set<Id> contactIds = new Set<Id>();
    for (Contact con : contacts) {
      contactIds.add(con.Id);
    }

    Test.startTest();

    IntegrationAppRetryDemo demo = new IntegrationAppRetryDemo();
    demo.init(execution, contactIds);
    System.enqueueJob(demo);

    Test.stopTest();

    // Verify successful execution
    List<KicksawEng__IntegrationExecution__c> updatedExecutions = [
      SELECT
        Id,
        KicksawEng__SuccessfulCompletion__c,
        Retry_Ids__c,
        Retry_From__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retry_From__c = NULL
      LIMIT 1
    ];

    System.assertEquals(
      true,
      updatedExecutions[0].KicksawEng__SuccessfulCompletion__c,
      'Execution should be marked as successful'
    );
    System.assertEquals(
      null,
      updatedExecutions[0].Retry_Ids__c,
      'No retry IDs should be set for successful execution'
    );

    // Verify no logs were created
    List<KicksawEng__IntegrationLog__c> logs = [
      SELECT Id
      FROM KicksawEng__IntegrationLog__c
      WHERE KicksawEng__IntegrationExecution__c = :execution.Id
    ];
    System.assertEquals(
      0,
      logs.size(),
      'No logs should be created for successful execution'
    );
  }

  @isTest
  static void testProcessRecordsHttpError() {
    // Setup error mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      500,
      'Internal Server Error',
      '{"error": "Server error occurred"}',
      new Map<String, String>{ 'Content-Type' => 'application/json' }
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    // Get test data
    List<Contact> contacts = [SELECT Id, Name, Email FROM Contact LIMIT 3];

    // Create execution record
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    Set<Id> contactIds = new Set<Id>();
    for (Contact con : contacts) {
      contactIds.add(con.Id);
    }

    Test.startTest();

    IntegrationAppRetryDemo demo = new IntegrationAppRetryDemo();
    demo.init(execution, contactIds);
    System.enqueueJob(demo);

    Test.stopTest();

    // Verify execution marked for retry
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT
        Id,
        KicksawEng__SuccessfulCompletion__c,
        Retry_Ids__c,
        Record_Id__c,
        Retry_From__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retry_From__c = NULL
      LIMIT 1
    ];

    System.assertEquals(
      false,
      updatedExecution.KicksawEng__SuccessfulCompletion__c,
      'Execution should not be marked as successful'
    );
    System.assertNotEquals(
      null,
      updatedExecution.Retry_Ids__c,
      'Retry IDs should be set for failed execution'
    );

    // Verify logs were created
    List<KicksawEng__IntegrationLog__c> logs = [
      SELECT Id, KicksawEng__LogMessage__c, Payload__c
      FROM KicksawEng__IntegrationLog__c
    ];
    System.assertEquals(
      contacts.size(),
      logs.size(),
      'One log should be created per failed contact'
    );
    System.assertNotEquals(
      null,
      logs[0].Payload__c,
      'Payload should be populated in the log'
    );
  }

  @isTest
  static void testProcessRecordsException() {
    // Setup mock that throws exception
    MockRequestSingle mockCallout = new MockRequestSingle(
      0,
      'throwException',
      null,
      null
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    // Get test data
    List<Contact> contacts = [SELECT Id, Name, Email FROM Contact LIMIT 2];

    // Create execution record
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    Set<Id> contactIds = new Set<Id>();
    for (Contact con : contacts) {
      contactIds.add(con.Id);
    }

    Test.startTest();

    IntegrationAppRetryDemo demo = new IntegrationAppRetryDemo();
    demo.init(execution, contactIds);
    System.enqueueJob(demo);

    Test.stopTest();

    // Verify execution marked for retry
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT
        Id,
        KicksawEng__SuccessfulCompletion__c,
        Retry_Ids__c,
        Retry_From__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retry_From__c = NULL
      LIMIT 1
    ];

    System.assertEquals(
      false,
      updatedExecution.KicksawEng__SuccessfulCompletion__c,
      'Execution should not be marked as successful'
    );
    System.assertNotEquals(
      null,
      updatedExecution.Retry_Ids__c,
      'Retry IDs should be set for failed execution'
    );

    // Verify exception logs were created
    List<KicksawEng__IntegrationLog__c> logs = [
      SELECT Id, KicksawEng__LogMessage__c, Payload__c
      FROM KicksawEng__IntegrationLog__c
      WHERE KicksawEng__IntegrationExecution__c = :updatedExecution.Id
    ];
    System.assertEquals(
      contacts.size(),
      logs.size(),
      'One log should be created per failed contact'
    );
    System.assertNotEquals(
      null,
      logs[0].Payload__c,
      'Payload should be populated in the log'
    );
  }

  @isTest
  static void testProcessRecordsWithRetryParent() {
    // Setup successful mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'OK',
      '{"success": true}',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    // Get test data
    List<Contact> contacts = [SELECT Id, Name, Email FROM Contact LIMIT 2];
    // Create Integration Execution record for retry scenario
    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c
      .getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    KicksawEng__Integration__c integration = [
      SELECT Id
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];

    KicksawEng__IntegrationExecution__c parentExecution = new KicksawEng__IntegrationExecution__c(
      KicksawEng__Integration__c = integration.Id,
      KicksawEng__SuccessfulCompletion__c = false,
      RecordTypeId = egressRecType,
      Retries_Attempted__c = 1
    );
    insert parentExecution;

    // Create execution record
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    Set<Id> contactIds = new Set<Id>();
    for (Contact con : contacts) {
      contactIds.add(con.Id);
    }

    Test.startTest();

    IntegrationAppRetryDemo demo = new IntegrationAppRetryDemo();
    demo.initRetry(execution, contactIds, parentExecution);
    System.enqueueJob(demo);

    Test.stopTest();

    // Verify execution marked as successful (find the retry execution)
    List<KicksawEng__IntegrationExecution__c> allExecutions = [
      SELECT Id, KicksawEng__SuccessfulCompletion__c
      FROM KicksawEng__IntegrationExecution__c
    ];

    KicksawEng__IntegrationExecution__c updatedExecution;
    for (KicksawEng__IntegrationExecution__c exec : allExecutions) {
      if (exec.Id != parentExecution.Id) {
        updatedExecution = exec;
        break;
      }
    }

    System.assertEquals(
      true,
      updatedExecution.KicksawEng__SuccessfulCompletion__c,
      'Execution should be marked as successful'
    );

    // Verify parent execution was updated
    KicksawEng__IntegrationExecution__c updatedParentExecution = [
      SELECT Id, KicksawEng__SuccessfulCompletion__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :parentExecution.Id
    ];

    System.assertEquals(
      true,
      updatedParentExecution.KicksawEng__SuccessfulCompletion__c,
      'Parent execution should be marked as successful'
    );
  }

  @isTest
  static void testRunIntegrationRetryDemoWithoutError() {
    // Setup successful mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'OK',
      '{"success": true}',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    IntegrationAppRetryDemo.runIntegrationRetryDemo();

    Test.stopTest();

    // Verify execution was created
    List<KicksawEng__IntegrationExecution__c> executions = [
      SELECT Id, KicksawEng__Integration__r.Name
      FROM KicksawEng__IntegrationExecution__c
      WHERE KicksawEng__Integration__r.Name = 'Integration Demo'
    ];

    System.assertEquals(
      1,
      executions.size(),
      'Should have 1 execution from the method'
    );
  }

  @isTest
  static void testRunIntegrationRetryDemoWithError() {
    // Setup error mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      404,
      'Not Found',
      '{"error": "Endpoint not found"}',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();

    IntegrationAppRetryDemo.runIntegrationRetryDemo(true);

    Test.stopTest();

    // Verify execution was created and failed
    List<KicksawEng__IntegrationExecution__c> executions = [
      SELECT Id, KicksawEng__SuccessfulCompletion__c, Retry_Ids__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE KicksawEng__Integration__r.Name = 'Integration Demo'
    ];

    System.assertEquals(
      1,
      executions.size(),
      'Should have 1 execution from the method'
    );

    KicksawEng__IntegrationExecution__c testExecution = executions[0];

    System.assertEquals(
      false,
      testExecution.KicksawEng__SuccessfulCompletion__c,
      'Execution should have failed'
    );
    System.assertNotEquals(
      null,
      testExecution.Retry_Ids__c,
      'Retry IDs should be populated for failed execution'
    );

    // Verify logs were created
    List<KicksawEng__IntegrationLog__c> logs = [
      SELECT Id
      FROM KicksawEng__IntegrationLog__c
      WHERE KicksawEng__IntegrationExecution__c = :testExecution.Id
    ];
    System.assert(
      logs.size() > 0,
      'Logs should be created for failed execution'
    );
  }

  @isTest
  static void testSingleContactRetry() {
    // Setup error mock response
    MockRequestSingle mockCallout = new MockRequestSingle(
      400,
      'Bad Request',
      '{"error": "Invalid request"}',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockCallout);

    // Get single contact
    Contact singleContact = [SELECT Id, Name, Email FROM Contact LIMIT 1];

    // Create execution record
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    Set<Id> contactIds = new Set<Id>{ singleContact.Id };

    Test.startTest();

    IntegrationAppRetryDemo demo = new IntegrationAppRetryDemo();
    demo.init(execution, contactIds);
    System.enqueueJob(demo);

    Test.stopTest();

    // Verify Record_Id__c is set for single contact retry
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Record_Id__c, Retry_Ids__c, Retry_From__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Retry_From__c = NULL
      LIMIT 1
    ];

    System.assertEquals(
      singleContact.Id,
      updatedExecution.Record_Id__c,
      'Record_Id__c should be set for single contact retry'
    );
    System.assertEquals(
      singleContact.Id,
      updatedExecution.Retry_Ids__c,
      'Retry_Ids__c should contain the single contact ID'
    );
  }
}
