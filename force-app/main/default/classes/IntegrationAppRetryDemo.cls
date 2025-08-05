public without sharing class IntegrationAppRetryDemo extends RetryIntegrationAbstractQueuable {
  Boolean triggerError = false;

  public override void initRetry(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds,
    KicksawEng__IntegrationExecution__c retryParentExecution
  ) {
    super.initializeVarRetry(execution, recordIds, retryParentExecution);
  }

  public override void init(
    KicksawEng__IntegrationExecution__c execution,
    Set<Id> recordIds
  ) {
    super.initializeVar(execution, recordIds);
  }

  public override void processRecords() {
    Set<Id> recordsToRetry = new Set<Id>(); //Keeps track of records that need to be retried
    List<KicksawEng__IntegrationLog__c> logs = new List<KicksawEng__IntegrationLog__c>(); //Keeps track of logs for the execution

    //logic to process the records
    List<Contact> contacts = [
      SELECT Id, Name, Email
      FROM Contact
      WHERE Id IN :recordIds
      LIMIT 10
    ];

    //If callouts need to be made one at a time, we can use a Set to keep track of records that need to be retried
    String endpoint = 'callout:ReqRes_API/api/users';
    system.debug('Trigger Error: ' + triggerError);
    if (triggerError) {
      endpoint = 'callout:ReqRes_API/invalidEndpointTesting';
    }

    for (Contact con : contacts) {
      Map<String, String> requestBodyMap = new Map<String, String>{
        'email' => con.Email != null
          ? con.Email
          : 'testemail' + con.Id + '@email.com',
        'password' => con.Id // Using Contact ID as password
      };

      String body = JSON.serialize(requestBodyMap);

      HttpRequest req = new HttpRequest();
      system.debug('Endpoint: ' + endpoint);
      req.setEndpoint(endpoint);
      req.setMethod('GET');
      req.setHeader('Content-Type', 'application/json');
      req.setBody(body);

      HttpResponse res = new HttpResponse();

      try {
        res = new Http().send(req);
        System.debug('Response: ' + res.getBody());
      } catch (System.Exception e) {
        System.debug('Error: ' + e.getMessage());
        recordsToRetry.add(con.Id); //This can be skipped if the record should not be retried

        //Create an execution log for the payload
        KicksawEng__IntegrationLog__c log = KicksawIntegration.createExceptionLogs(
          e
        );
        log.Payload__c = body;
        logs.add(log);
        continue;
      }

      if (res.getStatusCode() >= 400 || res.getStatusCode() == 0) {
        recordsToRetry.add(con.Id);
        KicksawEng__IntegrationLog__c log = KicksawIntegration.createIntegrationLogs(
          res
        );
        log.Payload__c = body;
        logs.add(log);
      }
    }

    //After processing the records, create the integration execution and log records and process the retry
    List<KicksawEng__IntegrationExecution__c> executionsToUpsert = new List<KicksawEng__IntegrationExecution__c>();

    //Create execution record so that the retry Ids can be added to the execution record
    if (recordsToRetry.size() > 0) {
      String retryIdsStr = String.join(recordsToRetry, ',');
      execution.Retry_Ids__c = retryIdsStr;
      if (recordsToRetry.size() == 1) {
        execution.Record_Id__c = recordsToRetry.iterator().next();
      }

      /* If this is a retry, the parent execution record will need to be updated to reflect the retry and we 
      would not want to create new retry execution records
      */

      if (retryParentExecution != null) {
        QueueablePostRetryProcessing retryProcessing = new QueueablePostRetryProcessing(
          retryParentExecution,
          recordsToRetry
        );
        System.enqueueJob(retryProcessing);
      }
    } else {
      /*If no records need to be retried, we can mark the execution as successful and update
       the parent execution record*/

      execution.KicksawEng__SuccessfulCompletion__c = true;
      execution.Next_Retry_Scheduled__c = null;
      if (retryParentExecution != null) {
        retryParentExecution.KicksawEng__SuccessfulCompletion__c = true;
        executionsToUpsert.add(retryParentExecution);
      }
    }

    executionsToUpsert.add(execution);
    upsert executionsToUpsert;

    if (logs.size() > 0) {
      for (KicksawEng__IntegrationLog__c log : logs) {
        log.KicksawEng__IntegrationExecution__c = execution.Id;
      }
      insert logs;
    }
  }

  public static void runIntegrationRetryDemo() {
    runIntegrationRetryDemo(false);
  }

  public static void runIntegrationRetryDemo(Boolean triggerError) {
    //create a new integration execution
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );

    //Getting record ids to use for the integration
    Map<Id, Contact> contactMap = new Map<Id, Contact>(
      [
        SELECT Id, Name
        FROM Contact
        LIMIT 10
      ]
    );

    IntegrationAppRetryDemo integration = new IntegrationAppRetryDemo();
    integration.init(execution, contactMap.keySet());
    if (triggerError) {
      integration.triggerError = true;
    }
    //Enqueue the queueable job
    System.enqueueJob(integration);
  }
}
