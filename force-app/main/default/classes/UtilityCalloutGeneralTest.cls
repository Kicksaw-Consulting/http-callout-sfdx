@isTest
public class UtilityCalloutGeneralTest {
  @isTest
  static void testSuccessfulCallout() {
    // Create mock response
    MockRequestSingle mockResponse = new MockRequestSingle(
      200,
      'OK',
      '{"success": true}',
      new Map<String, String>{ 'Content-Type' => 'application/json' }
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();

    // Initialize callout class
    UtilityCalloutGeneral callout = new UtilityCalloutGeneral('POST')
      .setNamedCredential('TestCredential')
      .setPath('/api/test')
      .setBody('{"test": "data"}')
      .setHeaders(
        new Map<String, String>{
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      );

    // Make the callout
    HTTPResponse response = callout.doCallout();

    Test.stopTest();

    // Verify response
    System.assertEquals(
      200,
      response.getStatusCode(),
      'Status code should be 200'
    );
    System.assertEquals(
      '{"success": true}',
      response.getBody(),
      'Response body should match'
    );
  }

  @isTest
  static void testCalloutWithoutHeaders() {
    // Create mock response
    MockRequestSingle mockResponse = new MockRequestSingle(
      200,
      'OK',
      '{"success": true}',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();

    // Initialize callout class without headers
    UtilityCalloutGeneral callout = new UtilityCalloutGeneral('GET')
      .setNamedCredential('TestCredential')
      .setPath('/api/test');

    // Make the callout
    HTTPResponse response = callout.doCallout();

    Test.stopTest();

    // Verify response
    System.assertEquals(
      200,
      response.getStatusCode(),
      'Status code should be 200'
    );
  }

  @isTest
  static void testCalloutWithoutBody() {
    // Create mock response
    MockRequestSingle mockResponse = new MockRequestSingle(
      204,
      'No Content',
      '',
      null
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();

    // Initialize callout class without body
    UtilityCalloutGeneral callout = new UtilityCalloutGeneral('DELETE')
      .setNamedCredential('TestCredential')
      .setPath('/api/test');

    // Make the callout
    HTTPResponse response = callout.doCallout();

    Test.stopTest();

    // Verify response
    System.assertEquals(
      204,
      response.getStatusCode(),
      'Status code should be 204'
    );
  }
}
