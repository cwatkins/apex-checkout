StripeCheckout.CheckoutService service = new StripeCheckout.CheckoutService(
  new MockStripeClient('https://test.com/checkout-session-id')
);

StripeCheckout.CheckoutRequest request = new StripeCheckout.CheckoutRequest();
request.priceItems = 'price_test,1';
request.customerEmail = 'test@example.com';
request.successUrl = 'https://test.com/success';
request.cancelUrl = 'https://test.com/cancel';

String result = service.createCheckoutSession(request);

// StripeCheckout.CheckoutRequest req = new StripeCheckout.CheckoutRequest();
// req.priceItems = 'price_1QLeeBIxbMEkLtTyvPS2mZPg,1';
// req.customerEmail = 'customer@example.com';
// req.successUrl = 'https://example.com/success';
// req.cancelUrl = 'https://example.com/cancel';
// req.clientReferenceId = 'order_ref_123';
// // req.customText = 'I agree to the Terms of Service and will pay the total amount.';

// // Other optional configurations
// // req.couponId = 'SUMMER2024';
// req.collectPhoneNumber = true;
// req.submitType = 'pay';
// req.enableExpirationRecovery = true;

// List<String> results = StripeCheckout.createCheckoutSessions(
//   new List<StripeCheckout.CheckoutRequest>{ req }
// );

// System.debug(results);
