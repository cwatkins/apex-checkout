public class StripeCheckout {
  private final String apiKey;
  private final HttpCalloutService http;

  public StripeCheckout() {
    this(
      Stripe_Configuration__mdt.getInstance('Default').API_Key__c,
      new HttpCalloutService()
    );
  }

  @TestVisible
  private StripeCheckout(String apiKey, HttpCalloutService http) {
    this.apiKey = apiKey;
    this.http = http;
  }

  @InvocableMethod(
    label='Create Stripe Checkout Session'
    description='Creates a Stripe checkout session from a list of price IDs and configuration'
    category='Stripe'
  )
  public static List<String> createCheckoutSessions(
    List<CheckoutRequest> requests
  ) {
    List<String> results = new List<String>();
    StripeCheckout stripe = new StripeCheckout();

    for (CheckoutRequest req : requests) {
      try {
        results.add(stripe.createCheckoutSession(req));
      } catch (Exception e) {
        results.add('Error: ' + e.getMessage());
      }
    }
    return results;
  }

  private String createCheckoutSession(CheckoutRequest req) {
    List<String> params = new List<String>();

    // Add line items
    List<String> items = req.priceItems.split(';');
    for (Integer i = 0; i < items.size(); i++) {
      List<String> parts = items[i].split(',');
      String priceId = parts[0].trim();
      Integer quantity = parts.size() > 1
        ? Integer.valueOf(parts[1].trim())
        : 1;

      params.add(
        'line_items[' +
          i +
          '][price]=' +
          EncodingUtil.urlEncode(priceId, 'UTF-8')
      );
      params.add('line_items[' + i + '][quantity]=' + quantity);
    }

    // Required params
    params.add('mode=payment');
    params.add(
      'success_url=' + EncodingUtil.urlEncode(req.successUrl, 'UTF-8')
    );
    params.add('cancel_url=' + EncodingUtil.urlEncode(req.cancelUrl, 'UTF-8'));
    params.add(
      'customer_email=' + EncodingUtil.urlEncode(req.customerEmail, 'UTF-8')
    );

    // Optional: Client Reference ID
    if (String.isNotBlank(req.clientReferenceId)) {
      params.add(
        'client_reference_id=' +
        EncodingUtil.urlEncode(req.clientReferenceId, 'UTF-8')
      );
    }

    // Optional: Custom Text
    if (String.isNotBlank(req.customText)) {
      params.add(
        'custom_text[after_submit][message]=' +
        EncodingUtil.urlEncode(req.customText, 'UTF-8')
      );
    }

    // Optional: Discounts
    if (String.isNotBlank(req.couponId)) {
      params.add(
        'discounts[0][coupon]=' + EncodingUtil.urlEncode(req.couponId, 'UTF-8')
      );
    }
    if (String.isNotBlank(req.promotionCode)) {
      params.add(
        'discounts[0][promotion_code]=' +
        EncodingUtil.urlEncode(req.promotionCode, 'UTF-8')
      );
    }

    // Optional: Phone Collection
    if (req.collectPhoneNumber) {
      params.add('phone_number_collection[enabled]=true');
    }

    // Optional: Submit Type
    if (String.isNotBlank(req.submitType)) {
      params.add(
        'submit_type=' + EncodingUtil.urlEncode(req.submitType, 'UTF-8')
      );
    }

    // Optional: After Expiration Recovery
    if (req.enableExpirationRecovery) {
      params.add('after_expiration[recovery][enabled]=true');
    }

    // Make request
    HttpResponse res = http.post(
      'https://api.stripe.com/v1/checkout/sessions',
      String.join(params, '&'),
      new Map<String, String>{
        'Authorization' => 'Bearer ' + apiKey,
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    );

    // Parse response
    Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );
    if (res.getStatusCode() == 200) {
      return (String) responseData.get('url');
    } else {
      Map<String, Object> error = (Map<String, Object>) responseData.get(
        'error'
      );
      throw new StripeException((String) error.get('message'));
    }
  }

  public class CheckoutRequest {
    // Required parameters
    @InvocableVariable(
      label='Price Items'
      description='Format: "priceId,quantity;priceId,quantity" Example: "price_H5ggYwtDq4fbrJ,1;price_L7khUytRq9gmK,2"'
      required=true
    )
    public String priceItems;

    @InvocableVariable(label='Customer Email' required=true)
    public String customerEmail;

    @InvocableVariable(label='Success URL' required=true)
    public String successUrl;

    @InvocableVariable(label='Cancel URL' required=true)
    public String cancelUrl;

    // Optional Parameters
    @InvocableVariable(
      label='Client Reference ID'
      description='A unique identifier for the checkout session'
      required=false
    )
    public String clientReferenceId;

    @InvocableVariable(
      label='Custom Terms Text'
      description='Custom text for Terms of Service acceptance message'
      required=false
    )
    public String customText;

    @InvocableVariable(
      label='Coupon ID'
      description='The ID of a coupon to apply'
      required=false
    )
    public String couponId;

    @InvocableVariable(
      label='Promotion Code'
      description='The ID of a promotion code to apply'
      required=false
    )
    public String promotionCode;

    @InvocableVariable(
      label='Collect Phone Number'
      description='Whether to collect the customer phone number'
      required=false
    )
    public Boolean collectPhoneNumber;

    @InvocableVariable(
      label='Submit Type'
      description='One of: auto, pay, book, donate'
      required=false
    )
    public String submitType;

    @InvocableVariable(
      label='Enable Expiration Recovery'
      description='Whether to enable recovery of expired sessions'
      required=false
    )
    public Boolean enableExpirationRecovery;
  }

  public class StripeException extends Exception {
  }
}
