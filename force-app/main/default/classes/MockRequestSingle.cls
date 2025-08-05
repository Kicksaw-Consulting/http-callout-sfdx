@isTest
public with sharing class MockRequestSingle implements HttpCalloutMock {
  protected Integer code;
  protected String status;
  protected String bodyStr;
  protected Map<String, String> responseHeaders;
  public Integer calloutCounter = 0;

  public MockRequestSingle(
    Integer code,
    String status,
    String bodyStr,
    Map<String, String> responseHeaders
  ) {
    this.code = code;
    this.status = status;
    this.bodyStr = bodyStr;
    this.responseHeaders = responseHeaders;
  }

  public HTTPResponse respond(HTTPRequest req) {
    System.debug('calloutCounter = ' + calloutCounter);
    calloutCounter++;
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(code);
    if (status == 'throwException') {
      CalloutException e = (CalloutException) CalloutException.class
        .newInstance();
      e.setMessage(
        'Unauthorized endpoint, please check Setup->Security->Remote site settings.'
      );
      throw e;
    } else {
      resp.setStatus(status);
    }

    resp.setBody(bodyStr);
    if (responseHeaders != null) {
      for (String key : responseHeaders.keySet()) {
        system.debug('Location: ' + responseHeaders.get(key));
        resp.setHeader(key, responseHeaders.get(key));
      }
    }

    return resp;
  }
}
