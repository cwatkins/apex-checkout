@IsTest
private class StripeCheckoutTest {
  @IsTest
  static void testSuccessfulCheckout() {
    // Arrange
    MockStripeClient mockClient = new MockStripeClient(
      'https://checkout.stripe.com/test'
    );
    StripeCheckout.CheckoutService service = new StripeCheckout.CheckoutService(
      mockClient
    );

    StripeCheckout.CheckoutRequest request = new StripeCheckout.CheckoutRequest();
    request.priceItems = 'price_123,1';
    request.customerEmail = 'test@example.com';
    request.successUrl = 'https://success.com';
    request.cancelUrl = 'https://cancel.com';

    // Act
    String result = service.createCheckoutSession(request);

    // Assert
    System.assertEquals('https://checkout.stripe.com/test', result);
  }

  private class MockStripeClient implements StripeCheckout.IStripeClient {
    private final String returnUrl;

    public MockStripeClient(String returnUrl) {
      this.returnUrl = returnUrl;
    }

    public String createCheckoutSession(Map<String, String> params) {
      return returnUrl;
    }
  }

  @IsTest
  static void testErrorHandling() {
    // Arrange
    MockErrorStripeClient mockClient = new MockErrorStripeClient();
    StripeCheckout.CheckoutService service = new StripeCheckout.CheckoutService(
      mockClient
    );

    StripeCheckout.CheckoutRequest request = new StripeCheckout.CheckoutRequest();
    request.priceItems = 'price_123,1';
    request.customerEmail = 'test@example.com';
    request.successUrl = 'https://success.com';
    request.cancelUrl = 'https://cancel.com';

    // Act
    String result = service.createCheckoutSession(request);

    // Assert
    System.assert(result.startsWith('Error:'));
  }

  private class MockErrorStripeClient implements StripeCheckout.IStripeClient {
    public String createCheckoutSession(Map<String, String> params) {
      throw new StripeCheckout.StripeException('Test error');
    }
  }
}