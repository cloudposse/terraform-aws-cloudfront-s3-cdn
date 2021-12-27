module "lambda_at_edge" {
  source = "../../modules/lambda@edge"

  enabled = local.enabled && var.lambda_at_edge_enabled

  functions = {
    origin_request = {
      source = [{
        # https://aws.amazon.com/blogs/networking-and-content-delivery/adding-http-security-headers-using-lambdaedge-and-amazon-cloudfront/
        content  = <<-EOT
        'use strict';

        exports.handler = (event, context, callback) => {

          //Get contents of response
          const response = event.Records[0].cf.response;
          const headers = response.headers;

          //Set new headers
          headers['strict-transport-security'] = [{key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubdomains; preload'}];
          headers['content-security-policy'] = [{key: 'Content-Security-Policy', value: "default-src 'none'; img-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'"}];
          headers['x-content-type-options'] = [{key: 'X-Content-Type-Options', value: 'nosniff'}];
          headers['x-frame-options'] = [{key: 'X-Frame-Options', value: 'DENY'}];
          headers['x-xss-protection'] = [{key: 'X-XSS-Protection', value: '1; mode=block'}];
          headers['referrer-policy'] = [{key: 'Referrer-Policy', value: 'same-origin'}];

          //Return modified response
          callback(null, response);
        };
        EOT
        filename = "index.js"
      }]
      runtime      = "nodejs12.x"
      handler      = "index.handler"
      event_type   = "origin-response"
      include_body = false
    }
  }

  context = module.this.context
}