@isTest
public with sharing class RetrySingleIntegrationExecutionTest {
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
  public static void testRetrySingleExecution() {
    MockRequestSingle mockCallout = new MockRequestSingle(
      200,
      'Success',
      '{"success": true}',
      null
    );

    KicksawEng__IntegrationExecution__c execution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      LIMIT 1
    ];

    Test.setMock(HttpCalloutMock.class, mockCallout);

    Test.startTest();
    RetrySingleIntegrationExecution.retrySingleExecution(
      new List<Id>{ execution.Id }
    );
    Test.stopTest();

    // Verify the execution was processed
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :execution.Id
    ];
  }

  @isTest
  public static void testRetrySingleExecutionWithInvalidClass() {
    // Update the integration to have an invalid Apex class name
    KicksawEng__Integration__c integration = [
      SELECT Id
      FROM KicksawEng__Integration__c
      LIMIT 1
    ];
    integration.Apex_Class_for_Retry__c = 'InvalidClassName';
    update integration;

    KicksawEng__IntegrationExecution__c execution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      LIMIT 1
    ];

    Test.startTest();
    RetrySingleIntegrationExecution.retrySingleExecution(
      new List<Id>{ execution.Id }
    );
    Test.stopTest();

    // Verify the execution was not processed due to invalid class
    KicksawEng__IntegrationExecution__c updatedExecution = [
      SELECT Id, Retries_Attempted__c
      FROM KicksawEng__IntegrationExecution__c
      WHERE Id = :execution.Id
    ];

    System.assertEquals(
      0,
      updatedExecution.Retries_Attempted__c,
      'Retry attempt should remain at 0 due to invalid class'
    );
  }
}
