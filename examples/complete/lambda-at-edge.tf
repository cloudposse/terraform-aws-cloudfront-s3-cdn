provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

module "lambda_at_edge" {
  source = "../../modules/lambda@edge"

  enabled = local.enabled && var.lambda_at_edge_enabled

  functions = {
    # Just for the sake of a viewer-request example, inject a useless header into the request from the viewer to CF
    viewer_request = {
      source = [{
        content  = <<-EOT
        'use strict';

        exports.handler = (event, context, callback) => {
            const { request } = event.Records[0].cf;

            request.headers['useless-header'] = [
                {
                    key: 'Useless-Header',
                    value: 'This header is absolutely useless.'
                }
            ];

            return callback(null, request);
        };
        EOT
        filename = "index.js"
      }]
      runtime      = "nodejs16.x"
      handler      = "index.handler"
      event_type   = "viewer-request"
      include_body = false
    },
    # Add custom header to the response
    viewer_response = {
      source_dir   = "lib"
      runtime      = "nodejs16.x"
      handler      = "index.handler"
      event_type   = "viewer-response"
      include_body = false
    },
    origin_request = {
      source_zip   = "origin-request.zip"
      runtime      = "nodejs16.x"
      handler      = "index.handler"
      event_type   = "origin-request"
      include_body = false
    },
    # Add security headers to the request from CF to the origin
    origin_response = {
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
      runtime      = "nodejs16.x"
      handler      = "index.handler"
      event_type   = "origin-response"
      include_body = false
    }
  }

  # A destruction delay is always enabled due to automated tests (see variable description for more information).
  destruction_delay = "20m"

  providers = {
    aws = aws.us-east-1
  }

  context = module.this.context
}