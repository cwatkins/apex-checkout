StripeCheckout.CheckoutRequest req = new StripeCheckout.CheckoutRequest();
req.priceItems = 'price_1QLeeBIxbMEkLtTyvPS2mZPg,1';
req.customerEmail = 'customer@example.com';
req.successUrl = 'https://example.com/success';
req.cancelUrl = 'https://example.com/cancel';
req.clientReferenceId = 'order_ref_123';
// req.customText = 'I agree to the Terms of Service and will pay the total amount.';

// Other optional configurations
// req.couponId = 'SUMMER2024';
req.collectPhoneNumber = true;
req.submitType = 'pay';
req.enableExpirationRecovery = true;

List<String> results = StripeCheckout.createCheckoutSessions(
  new List<StripeCheckout.CheckoutRequest>{ req }
);

System.debug(results);
