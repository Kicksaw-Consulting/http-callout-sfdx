@isTest
public with sharing class KicksawIntegrationTests {
    @isTest
    static void insertLogs() {
        HTTPResponse respSuccess = new HttpResponse();
        respSuccess.setStatusCode(200);
        respSuccess.setBody('test1');

        HTTPResponse respFailure = new HttpResponse();
        respSuccess.setStatusCode(400);
        respSuccess.setBody('test2');

        List<KicksawEng__IntegrationLog__c> logs = new List<KicksawEng__IntegrationLog__c>();

        logs.add(KicksawIntegration.createIntegrationLogs(respSuccess));
        logs.add(KicksawIntegration.createIntegrationLogs(respFailure, 'customtest1'));

        try {
            throw new AuraHandledException('auratest');
        } catch(Exception e) {
            logs.add(KicksawIntegration.createExceptionLogs(e));
            logs.add(KicksawIntegration.createExceptionLogs(e, 'customtest2'));
        }

        KicksawIntegration.handleIntegrationLogs('test', logs);

        List<KicksawEng__IntegrationLog__c> tests = [SELECT Id FROM KicksawEng__IntegrationLog__c];
        System.assertEquals(4, tests.size());

        // TODO: Update to check values
    }
}