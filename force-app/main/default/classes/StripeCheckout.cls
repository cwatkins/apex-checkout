public class StripeCheckout {
  // Invocable method at top level
  @InvocableMethod(
    label='Create Stripe Checkout Session'
    description='Creates a Stripe checkout session'
    category='Stripe'
  )
  public static List<String> createCheckoutSessions(
    List<CheckoutRequest> requests
  ) {
    List<String> results = new List<String>();
    CheckoutService service = new CheckoutService();

    for (CheckoutRequest req : requests) {
      results.add(service.createCheckoutSession(req));
    }
    return results;
  }

  // Service class to handle checkout operations
  public class CheckoutService {
    private final IStripeClient stripeClient;

    public CheckoutService() {
      this(
        new StripeClient(new DefaultStripeConfig(), new DefaultHttpClient())
      );
    }

    @TestVisible
    public CheckoutService(IStripeClient stripeClient) {
      this.stripeClient = stripeClient;
    }

    public String createCheckoutSession(CheckoutRequest request) {
      try {
        Map<String, String> params = buildParams(request);
        System.debug('About to call stripeClient.createCheckoutSession');
        System.debug('stripeClient: ' + stripeClient);
        String result = stripeClient.createCheckoutSession(params);
        System.debug('Result from createCheckoutSession: ' + result);
        return result;
      } catch (Exception e) {
        System.debug('Exception type: ' + e.getTypeName());
        System.debug('Exception message: ' + e.getMessage());
        System.debug('Exception stack trace: ' + e.getStackTraceString());
        return 'Error: ' + e.getMessage();
      }
    }
    private Map<String, String> buildParams(CheckoutRequest req) {
      Map<String, String> params = new Map<String, String>();
      addLineItems(params, req.priceItems);
      addRequiredParams(params, req);
      addOptionalParams(params, req);
      return params;
    }

    private void addLineItems(Map<String, String> params, String priceItems) {
      List<String> items = priceItems.split(';');
      for (Integer i = 0; i < items.size(); i++) {
        List<String> parts = items[i].split(',');
        params.put('line_items[' + i + '][price]', parts[0].trim());
        params.put(
          'line_items[' + i + '][quantity]',
          parts.size() > 1 ? parts[1].trim() : '1'
        );
      }
    }

    private void addRequiredParams(
      Map<String, String> params,
      CheckoutRequest req
    ) {
      params.put('mode', 'payment');
      params.put('success_url', req.successUrl);
      params.put('cancel_url', req.cancelUrl);
      params.put('customer_email', req.customerEmail);
    }

    private void addOptionalParams(
      Map<String, String> params,
      CheckoutRequest req
    ) {
      if (String.isNotBlank(req.clientReferenceId)) {
        params.put('client_reference_id', req.clientReferenceId);
      }
      if (String.isNotBlank(req.customText)) {
        params.put('custom_text[after_submit][message]', req.customText);
      }
      if (String.isNotBlank(req.couponId)) {
        params.put('discounts[0][coupon]', req.couponId);
      }
      if (String.isNotBlank(req.promotionCode)) {
        params.put('discounts[0][promotion_code]', req.promotionCode);
      }
      if (req.collectPhoneNumber) {
        params.put('phone_number_collection[enabled]', 'true');
      }
      if (String.isNotBlank(req.submitType)) {
        params.put('submit_type', req.submitType);
      }
      if (req.enableExpirationRecovery) {
        params.put('after_expiration[recovery][enabled]', 'true');
      }
    }
  }

  // Interfaces and implementations
  public interface IStripeConfig {
    String getApiKey();
  }

  public class DefaultStripeConfig implements IStripeConfig {
    public String getApiKey() {
      return Stripe_Configuration__mdt.getInstance('Default').API_Key__c;
    }
  }

  public interface IHttpClient {
    HttpResponse send(HttpRequest req);
  }

  public class DefaultHttpClient implements IHttpClient {
    public HttpResponse send(HttpRequest req) {
      return new Http().send(req);
    }
  }

  public interface IStripeClient {
    String createCheckoutSession(Map<String, String> params);
  }

  public class StripeClient implements IStripeClient {
    private final IStripeConfig config;
    private final IHttpClient httpClient;

    public StripeClient(IStripeConfig config, IHttpClient httpClient) {
      this.config = config;
      this.httpClient = httpClient;
    }

    public String createCheckoutSession(Map<String, String> params) {
      HttpRequest req = buildRequest(params);
      HttpResponse res = httpClient.send(req);
      return handleResponse(res);
    }

    private HttpRequest buildRequest(Map<String, String> params) {
      HttpRequest req = new HttpRequest();
      req.setEndpoint('https://api.stripe.com/v1/checkout/sessions');
      req.setMethod('POST');
      req.setHeader('Authorization', 'Bearer ' + config.getApiKey());
      req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
      req.setBody(encodeParams(params));
      return req;
    }

    private String handleResponse(HttpResponse res) {
      Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );

      if (res.getStatusCode() == 200) {
        return (String) responseData.get('url');
      }

      Map<String, Object> error = (Map<String, Object>) responseData.get(
        'error'
      );
      throw new StripeException((String) error.get('message'));
    }

    private String encodeParams(Map<String, String> params) {
      List<String> encodedParams = new List<String>();
      for (String key : params.keySet()) {
        encodedParams.add(
          EncodingUtil.urlEncode(key, 'UTF-8') +
            '=' +
            EncodingUtil.urlEncode(params.get(key), 'UTF-8')
        );
      }
      return String.join(encodedParams, '&');
    }
  }

  // Request class
  public class CheckoutRequest {
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

    public CheckoutRequest() {
      this.collectPhoneNumber = false;
      this.enableExpirationRecovery = false;
    }
  }

  // Exception class
  public class StripeException extends Exception {
  }
}
