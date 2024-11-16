@IsTest
private class StripeCheckoutTest {
  private class MockHttpCallout implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;
    public HttpRequest lastRequest;

    public MockHttpCallout(Integer statusCode, String responseBody) {
      this.statusCode = statusCode;
      this.responseBody = responseBody;
    }

    public HttpResponse respond(HttpRequest req) {
      this.lastRequest = req;
      HttpResponse res = new HttpResponse();
      res.setStatusCode(statusCode);
      res.setBody(responseBody);
      return res;
    }
  }

  @IsTest
  static void testSuccessfulCheckout() {
    // Arrange
    String mockResponse = '{"url": "https://checkout.stripe.com/pay/test"}';
    MockHttpCallout mock = new MockHttpCallout(200, mockResponse);
    Test.setMock(HttpCalloutMock.class, mock);

    StripeCheckout.CheckoutRequest req = new StripeCheckout.CheckoutRequest();
    req.priceItems = 'price_test123,2';
    req.customerEmail = 'test@example.com';
    req.successUrl = 'https://success.com';
    req.cancelUrl = 'https://cancel.com';

    // Act
    Test.startTest();
    List<String> results = StripeCheckout.createCheckoutSessions(
      new List<StripeCheckout.CheckoutRequest>{ req }
    );
    Test.stopTest();

    // Assert
    System.assertEquals('https://checkout.stripe.com/pay/test', results[0]);
    System.assert(mock.lastRequest.getBody().contains('price_test123'));
    System.assert(
      mock.lastRequest.getHeader('Authorization').startsWith('Bearer ')
    );
  }

  @IsTest
  static void testErrorResponse() {
    // Arrange
    String mockResponse = '{"error": {"message": "Invalid API Key"}}';
    Test.setMock(HttpCalloutMock.class, new MockHttpCallout(401, mockResponse));

    StripeCheckout.CheckoutRequest req = new StripeCheckout.CheckoutRequest();
    req.priceItems = 'price_test123,1';
    req.customerEmail = 'test@example.com';
    req.successUrl = 'https://success.com';
    req.cancelUrl = 'https://cancel.com';

    // Act
    Test.startTest();
    List<String> results = StripeCheckout.createCheckoutSessions(
      new List<StripeCheckout.CheckoutRequest>{ req }
    );
    Test.stopTest();

    // Assert
    System.assert(results[0].startsWith('Error: '));
  }
}
