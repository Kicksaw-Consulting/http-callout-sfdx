public without sharing class KicksawIntegration {
  public static KicksawEng__IntegrationExecution__c createIntegrationExecution(
    String appName
  ) {
    Id integAppId;
    Decimal retryInterval;
    KicksawEng__IntegrationExecution__c integEx = new KicksawEng__IntegrationExecution__c();

    List<KicksawEng__Integration__c> integ = [
      SELECT Id, Retry_Interval__c
      FROM KicksawEng__Integration__c
      WHERE Name = :appName
      LIMIT 1
    ];

    Id egressRecType = Schema.SObjectType.KicksawEng__IntegrationExecution__c.getRecordTypeInfosByName()
      .get('Egress')
      .getRecordTypeId();

    if (integ.size() > 0) {
      integAppId = integ[0].Id;
      retryInterval = integ[0].Retry_Interval__c;
    } else {
      //Create Integration App if it doesn't already exist
      Id appRTId = [
        SELECT Id
        FROM RecordType
        WHERE SObjectType = 'KicksawEng__Integration__c' AND Name = 'Egress'
        LIMIT 1
      ]
      .Id;

      KicksawEng__Integration__c newApp = new KicksawEng__Integration__c(
        Name = appName,
        recordTypeId = appRTId
      );

      insert newApp;
      integAppId = newApp.Id;
    }

    integEx = new KicksawEng__IntegrationExecution__c(
      recordTypeId = egressRecType,
      KicksawEng__Integration__c = integAppId,
      Next_Retry_Scheduled__c = retryInterval != null
        ? Datetime.now().addMinutes(Integer.valueOf(retryInterval))
        : null
    );
    return integEx;
  }

  public static KicksawEng__IntegrationLog__c createIntegrationLogs(
    HTTPResponse resp
  ) {
    System.debug('KicksawIntegration.createIntegrationLogs');
    KicksawEng__IntegrationLog__c integLog = new KicksawEng__IntegrationLog__c(
      KicksawEng__LogLevel__c = resp.getStatusCode() < 400 ? 'INFO' : 'ERROR',
      KicksawEng__StatusCode__c = resp.getStatusCode(),
      KicksawEng__LogMessage__c = resp.getStatusCode() < 400
        ? null
        : trimmedString(resp.getBody())
    );
    return integLog;
  }

  public static KicksawEng__IntegrationLog__c createIntegrationLogs(
    HTTPResponse resp,
    String customMessage
  ) {
    System.debug('KicksawIntegration.createIntegrationLogs');
    KicksawEng__IntegrationLog__c integLog = new KicksawEng__IntegrationLog__c(
      KicksawEng__LogLevel__c = resp.getStatusCode() < 400 ? 'INFO' : 'ERROR',
      KicksawEng__StatusCode__c = resp.getStatusCode(),
      KicksawEng__LogMessage__c = customMessage
    );
    return integLog;
  }

  public static KicksawEng__IntegrationLog__c createExceptionLogs(Exception e) {
    System.debug('KicksawIntegration.createIntegrationLogs');
    KicksawEng__IntegrationLog__c integLog = new KicksawEng__IntegrationLog__c(
      KicksawEng__LogLevel__c = 'ERROR',
      KicksawEng__StatusCode__c = null,
      KicksawEng__LogMessage__c = e.getMessage()
    );
    return integLog;
  }

  public static KicksawEng__IntegrationLog__c createExceptionLogs(
    Exception e,
    String customMessage
  ) {
    System.debug('KicksawIntegration.createIntegrationLogs');
    KicksawEng__IntegrationLog__c integLog = new KicksawEng__IntegrationLog__c(
      KicksawEng__LogLevel__c = 'ERROR',
      KicksawEng__StatusCode__c = null,
      KicksawEng__LogMessage__c = customMessage
    );
    return integLog;
  }

  public static KicksawEng__IntegrationLog__c createExceptionLogs(
    String logLevel,
    Integer statusCode,
    String customMessage
  ) {
    System.debug('KicksawIntegration.createIntegrationLogs');
    KicksawEng__IntegrationLog__c integLog = new KicksawEng__IntegrationLog__c(
      KicksawEng__LogLevel__c = logLevel,
      KicksawEng__StatusCode__c = statusCode,
      KicksawEng__LogMessage__c = customMessage
    );
    return integLog;
  }

  public static void handleIntegrationLogs(
    String integrationName,
    List<KicksawEng__IntegrationLog__c> logs
  ) {
    KicksawEng__IntegrationExecution__c integEx = KicksawIntegration.createIntegrationExecution(
      integrationName
    );

    System.debug('logs.size() = ' + logs.size());
    if (logs.size() > 0) {
      //Create Kicksaw Integration Execution- Needs to be created after callout to prevent uncommited work pending error
      integEx.KicksawEng__SuccessfulCompletion__c = false;
      insert integEx;

      for (KicksawEng__IntegrationLog__c log : logs) {
        log.KicksawEng__IntegrationExecution__c = integEx.Id;
      }
      insert logs;
    } else {
      integEx.KicksawEng__SuccessfulCompletion__c = true;
      insert integEx;
    }
  }

  public class IntegrationException extends Exception {
  }

  public static String trimmedString(String str) {
    if (str.length() > 131072) {
      //Max field length
      return str.substring(0, 131072);
    }
    return str;
  }
}
