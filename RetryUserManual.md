## Integrations Retry

- Each integration has an Integration record in the Kicksaw Integrations App inside Salesforce. To open the app, search for “Kicksaw Integrations” in the app search bar, then click on the Integrations tab. You will need either Integration App Admin or Integration App Permissions to see the app.

- To enable retry, complete the follow fields on the Integration record:
  - Apex Class for Retry- This will be the API name of the Apex Class that is called during retries. Please reach out to the Kicksaw team for help in finding the Apex Class name
  - Maximum Retries- The maximum number of retries that should be attempted for each execution of the integration. Each execution is each time the integration runs.
  - Retry Interval- The duration of time between each retry attempts, it needs to be in increments of 15minutes
  - Status Codes to Retry- Comma-separated list of status codes that retries should be attempted. e.g. 400,408. If it's not entered, thenit will be any status code
  - Enable Retry - Checkbox needs to be checked
- An Apex batch job is scheduled to run every 15 minutes to search for Integration Execution records that should be retried, and it will run the retries using the Apex Class name specified on the Integration record

### For Developers

To create an integration with the retry feature enabled:

- Integration Record needs to be manually created with all the required fields completed (see section above)

- Create an Apex Class that extends the RetryIntegrationAbstractQueuable class and override the initRetry, init, and processRecords abstract methods
  - initRetry method requires 3 parameters: KicksawEng**IntegrationExecution**c execution, Set<Id> recordIds, and KicksawEng**IntegrationExecution**c retryParentExecution
    - This method is used to initialize the variables when the class is called in the retry context. It allows the parent execution record to be updated after the callouts (otherwise uncommitted work pending error will occur)
    - recordIds is the list of record Ids that you want to retry for
  - init method takes in KicksawEng**IntegrationExecution**c execution and Set<Id> recordIds
    - This method is used when the class is not in a retry context and this is a new execution of the integration
  - processRecords method does not take in any parameters, and this is where the business logic of the class is found
  * The reason why init methods need to be used to initialize variables rather than constructor is because The retry batch class needs to be able to dynamically call the Apex Class. When the Apex Class is called using Type.newInstance(), parameters cannot be passed through the constructor. This is an Apex limitation
  ```java
          Type apexClassType = Type.forName(
            executions[i].KicksawEng__Integration__r.Apex_Class_for_Retry__c
          );
          RetryIntegrationAbstractQueuable retryableClass = (RetryIntegrationAbstractQueuable) apexClassType.newInstance();
  ```
- KicksawEng**IntegrationExecution**c record needs to be initialized outside of the retryable Apex Class to prevent recursive creation of execution records.
  - The execution record will need Retry_Ids\_\_c the field populated and this is passed by the initRetry method
  - To initialize an execution record:
  ```java
    KicksawEng__IntegrationExecution__c execution = KicksawIntegration.createIntegrationExecution(
      'Integration Demo'
    );
  ```
  The name you pass in has to match the name of the Integration record that was manually created
- IntegrationExecution record needs to be inserted after the callouts to prevent “uncommitted work pending” error. QueueablePostRetryProcessing class is used to update the Parent Execution record if the retry has failed.

- To schedule for Automatic Retries, the batch classes need to be scheduled to run every 15 minutes:

```java
//Run every 15 minutes
BatchIntegrationExecutionRetry scheduler = new BatchIntegrationExecutionRetry();
System.schedule(
  'Integration Execution Retry Batch 1',
  '0 0 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 2',
  '0 15 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 3',
  '0 30 * * * ?',
  scheduler
);
System.schedule(
  'Integration Execution Retry Batch 4',
  '0 45 * * * ?',
  scheduler
);
```

- Since the batch process runs as the Automated Process user, the permission set that contains the permission to the External Credential will need to be assigned to the Automated Process user. See 'assignPermissionSetToAutomatedUser.apex' for an example. Replace the script with the API name of the permission set to assign

### For Testing

An example is written in IntegrationAppRetryDemo class, if you want to trigger an error to see how an error Integration Execution record looks like, you can run this in Anonymous Apex

```
IntegrationAppRetryDemo.runIntegrationRetryDemo(true);
```

If you retry this execution, it should result in success. Passing true in the class will call a non-existent endpoint which will trigger a 404 status code.
