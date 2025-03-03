'use strict';

exports.handler = (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    // Add a custom header to the response
    headers['x-custom-header'] = [{ key: 'X-Custom-Header', value: 'My custom value' }];
    headers['x-my-response-header'] = [{ key: 'X-My-Response-Header', value: process.env.MY_RESPONSE_HEADER }];

    callback(null, response);
};
