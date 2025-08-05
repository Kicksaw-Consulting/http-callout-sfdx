public without sharing virtual class UtilityCalloutGeneral {
  public String body;
  public Map<String, String> headers;
  public String namedCredential;
  public String path = '';
  public String method;

  public UtilityCalloutGeneral(String method) {
    this.method = method;
  }

  public UtilityCalloutGeneral setBody(String body) {
    this.body = body;
    return this;
  }

  public UtilityCalloutGeneral setHeaders(Map<String, String> headers) {
    this.headers = headers;
    return this;
  }

  public UtilityCalloutGeneral setNamedCredential(String namedCredential) {
    this.namedCredential = namedCredential;
    return this;
  }

  public UtilityCalloutGeneral setPath(String path) {
    this.path = path;
    return this;
  }

  public virtual HTTPResponse doCallout() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:' + this.namedCredential + this.path);
    req.setMethod(this.method);
    req.setTimeout(120000);

    if (headers != null) {
      for (String key : headers.keySet()) {
        req.setHeader(key, headers.get(key));
      }
    }

    if (this.body != null)
      req.setBody(this.body);
    Http http = new Http();
    HTTPResponse res = http.send(req);

    return res;
  }
}
