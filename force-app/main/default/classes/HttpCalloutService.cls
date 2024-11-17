public class HttpCalloutService implements IHttpCalloutService {
  public HttpResponse post(
    String endpoint,
    String body,
    Map<String, String> headers
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('POST');
    req.setBody(body);

    for (String key : headers.keySet()) {
      req.setHeader(key, headers.get(key));
    }

    return new Http().send(req);
  }
}