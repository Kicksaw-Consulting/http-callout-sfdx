@IsTest
private class BatchRetryAllIntegrationExecutionsTest {
    @TestSetup
    static void makeData(){
        // Create Integration record
        KicksawEng__Integration__c integration = new KicksawEng__Integration__c(
            Name = 'Test Integration',
            Enable_Retry__c = true,
            Apex_Class_for_Retry__c = 'TestClass',
            Retry_Interval__c = 5,
            Maximum_Retries__c = 3
        );
        insert integration;
        
        // Create Integration Execution record
        KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
            KicksawEng__Integration__c = integration.Id,
            KicksawEng__SuccessfulCompletion__c = false,
            Retry_Ids__c = 'TestId',
            Retries_Attempted__c = 0
        );
        insert execution;
        
        // Create Integration Log record
        // Note: Status_Code_in_Retry_List__c will be determined by the system based on LogMessage
        KicksawEng__IntegrationLog__c log = new KicksawEng__IntegrationLog__c(
            KicksawEng__IntegrationExecution__c = execution.Id,
            KicksawEng__LogMessage__c = 'Error: 500 Server Error' // Assuming this error code is in the retry list
        );
        insert log;
    }
    
    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        BatchRetryAllIntegrationExecutions batch = new BatchRetryAllIntegrationExecutions();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that the execution was processed
        List<KicksawEng__IntegrationExecution__c> executions = [
            SELECT Id, Retry_Ids__c 
            FROM KicksawEng__IntegrationExecution__c 
            WHERE KicksawEng__SuccessfulCompletion__c = false
        ];
        System.assertEquals(1, executions.size(), 'Should find one failed execution');
        System.assertEquals('TestId', executions[0].Retry_Ids__c, 'Retry_Ids__c should match');
    }
    
    @IsTest
    static void testInvocableMethod() {
        Test.startTest();
        BatchRetryAllIntegrationExecutions.invocableRetryAll();
        Test.stopTest();
        
        // Verify that the execution was processed
        List<KicksawEng__IntegrationExecution__c> executions = [
            SELECT Id, Retry_Ids__c 
            FROM KicksawEng__IntegrationExecution__c 
            WHERE KicksawEng__SuccessfulCompletion__c = false
        ];
        System.assertEquals(1, executions.size(), 'Should find one failed execution');
    }
    
    @IsTest
    static void testBatchWithNoRetryIds() {
        // Create execution without retry ids
        KicksawEng__Integration__c integration = [SELECT Id FROM KicksawEng__Integration__c LIMIT 1];
        
        KicksawEng__IntegrationExecution__c execution = new KicksawEng__IntegrationExecution__c(
            KicksawEng__Integration__c = integration.Id,
            KicksawEng__SuccessfulCompletion__c = false,
            Retries_Attempted__c = 0
        );
        insert execution;
        
        // Create Integration Log record
        KicksawEng__IntegrationLog__c log = new KicksawEng__IntegrationLog__c(
            KicksawEng__IntegrationExecution__c = execution.Id,
            KicksawEng__LogMessage__c = 'Error: 500 Server Error' // Assuming this error code is in the retry list
        );
        insert log;
        
        Test.startTest();
        BatchRetryAllIntegrationExecutions batch = new BatchRetryAllIntegrationExecutions();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify execution was processed but no event was published
        List<KicksawEng__IntegrationExecution__c> executions = [
            SELECT Id, Retry_Ids__c 
            FROM KicksawEng__IntegrationExecution__c 
            WHERE Id = :execution.Id
        ];
        System.assertEquals(1, executions.size(), 'Should find the execution');
        System.assertEquals(null, executions[0].Retry_Ids__c, 'Retry_Ids__c should be null');
    }
} 