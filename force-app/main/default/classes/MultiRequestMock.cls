@isTest
public class MultiRequestMock implements HttpCalloutMock {
  Map<String, MockRequestSingle> requests;

  public MultiRequestMock(Map<String, MockRequestSingle> requests) {
    this.requests = requests;
  }

  public HTTPResponse respond(HTTPRequest req) {
    String path = req.getEndpoint().substringBetween('/', '?');
    MockRequestSingle mock = requests.get(path);
    if (mock != null) {
      return mock.respond(req);
    } else {
      mock = requests.get('genericMock');
      return mock.respond(req);
    }
  }

  public void addRequestMock(String url, MockRequestSingle mock) {
    requests.put(url, mock);
  }
}
