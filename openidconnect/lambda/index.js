'use strict';

//const AWS = require('aws-sdk');
const cookie = require('cookie');
const crypto = require('crypto');
const https = require('https');
const jwt = require('jsonwebtoken');
const querystring = require('querystring');


const PARAMETERS = require('./config.json');

const LOGIN_ENDPOINT = '/login';

const UNAUTHORIZED_RESPONSE = {
    status: '401',
    statusDescription: 'OK',
    headers: {
        'content-type': [
            {
                key: 'Content-Type',
                value: 'text/html'
            }
        ],
        'cache-control': [
            {
                key: 'Cache-Control',
                value: 'private'
            }
        ]
    },
    body: '<html><head><title>Unauthorized</title></head><body><h1>401 Unauthorized</h1></body></html>'
};
const LOGIN_RESPONSE = {
    status: '302',
    statusDescription: 'Found',
    headers: {
        location: [
            {
                key: 'Location',
                value: null // Set by generateLoginResponse()
            }
        ],
        'cache-control': [
            {
                key: 'Cache-Control',
                value: 'private'
            }
        ]
    }
};
const LOGIN_SUCCESSFUL_RESPONSE = {
    status: '302',
    statusDescription: 'Found',
    headers: {
        location: [
            {
                key: 'Location',
                value: '/index.html'
            }
        ],
        'cache-control': [
            {
                key: 'Cache-Control',
                value: 'private'
            }
        ],
        'set-cookie': [
            {
                key: 'Set-Cookie',
                value: null // Set by generateLoginSuccessfulResponse()
            }
        ],
    }
};

function getTokens(authCode, lambdaHost) {
    return new Promise((resolve, _) => {
        const reqOptions = {
            method: 'POST',
            hostname: PARAMETERS.DOMAIN,
            path: '/oauth2/token',
            auth: `${PARAMETERS.CLIENT_ID}:${PARAMETERS.CLIENT_SECRET}`,
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            timeout: PARAMETERS.TIMEOUT_MS
        };
        const reqPayload = querystring.stringify({
            grant_type: 'authorization_code',
            redirect_uri: `https://${lambdaHost}${LOGIN_ENDPOINT}`,
            tenantId: `${PARAMETERS.TENANT_ID}`,
            code: authCode
        });
        const req = https.request(reqOptions, res => {
            if (res.statusCode === 200) {
                let rawData = '';

                res.on('data', chunk => {
                    rawData += chunk;
                });

                res.on('end', () => {
                    const jsonResponse = JSON.parse(rawData);
                    if (    'id_token' in jsonResponse) {
                        console.debug('request succeeded');
                        const payload = jwt.decode(jsonResponse.access_token);
                        if (PARAMETERS.ROLE && PARAMETERS.ROLE != "") {
                          if (!payload.roles.includes(PARAMETERS.ROLE)) {
                            console.debug('Role ' + PARAMETERS.ROLE + ' not in ', payload.roles);
                            resolve(null);
                          }
                        }
                        resolve({idToken: jsonResponse.id_token});
                    } else {
                        console.error('request failed: unexpected response');
                        resolve(null);
                    }
                });
            } else {
                console.error(`request failed: server returned ${res.statusCode}`);
                res.resume(); // Response data needs to be consumed manually because there is no data handler in this case
                resolve(null);
            }
        });

        req.on('error', error => {
            console.error(`request failed: ${error.message}`);
            resolve(null);
        });

        req.write(reqPayload);
        req.end();
    });
}

async function getAuth(requestHeaders) {
    if (requestHeaders.cookie) {
        console.debug(`Found ${requestHeaders.cookie.length} Cookie headers`);

        for (let i = 0; i < requestHeaders.cookie.length; ++i) {
            const cookies = cookie.parse(requestHeaders.cookie[i].value);

            if (PARAMETERS.AUTH_COOKIE_NAME in cookies) {
                console.debug(`Auth cookie found at Cookie header index ${i}`);

                const signedJwt = cookies[PARAMETERS.AUTH_COOKIE_NAME];

                try {
                    const decodedJwt = jwt.verify(signedJwt, PARAMETERS.JWT_SECRET);
                    console.debug(`JWT verified, expires at ${decodedJwt.exp}`);
                    return decodedJwt;
                } catch (err) {
                    console.warn(`JWT verification error: ${err.message}`);
                }
            } else {
                console.debug(`Auth cookie not found at Cookie header index ${i}`);
            }
        }
    } else {
        console.debug('No Cookie headers in request');
    }

    return null;
}

async function generateAuthCookie(Tokens) {
    const jwtPayload = {
        idToken: Tokens.idToken,
        refreshToken: ''
    };
    const jwtOptions = {
        algorithm: 'HS256',
        expiresIn: parseInt(PARAMETERS.AUTH_COOKIE_TTL_SEC)
    };
    // TODO: add salt
    const signedJwt = jwt.sign(jwtPayload, PARAMETERS.JWT_SECRET, jwtOptions);

    // Secure => Cookie is only sent to the server when a request is made with the https: scheme (except on localhost).
    // HttpOnly => Forbids JavaScript from accessing the cookie, for example, through the Document.cookie property.
    // SameStrict=Lax => Cookies are not sent on normal cross-site subrequests, but are sent when a user is navigating to the origin site.
    return `${PARAMETERS.AUTH_COOKIE_NAME}=${signedJwt}; Secure; HttpOnly; SameSite=Lax`;
}

function generateLoginResponse(lambdaHost) {
    const response = LOGIN_RESPONSE;
    const nonce = crypto.randomBytes(32).toString('hex');

    response.headers.location[0].value = `https://${PARAMETERS.DOMAIN}/oauth2/authorize?` +
        `client_id=${PARAMETERS.CLIENT_ID}` +
        `&nonce=${nonce}` +
        `&redirect_uri=https://${lambdaHost}${LOGIN_ENDPOINT}` +
        `&response_type=code` +
        '&response_mode=query' +
        `&scope=openid` +
        `&state=none`;

    return response;
}

async function generateLoginSuccessfulResponse(Tokens) {
    const response = LOGIN_SUCCESSFUL_RESPONSE;

    if (Tokens !== null) {
        response.headers['set-cookie'][0].value = await generateAuthCookie(Tokens);
    } else {
        delete response.headers['set-cookie'];
    }

    return response;
}

exports.auth = async (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    const lambdaHost = headers.host[0].value;
    const queryParams = querystring.parse(request.querystring);

    console.info(`${request.method} ${request.uri}` +
        (request.querystring ? `?${request.querystring}` : ''));

    const verifiedJwt = await getAuth(headers);

    if (verifiedJwt !== null) {
        // TODO: refresh token if it expires soon
        // TODO: revoke JWT if  token was revoked before end of the TTL
        if (request.uri === LOGIN_ENDPOINT) {
            console.info('Already authenticated, redirecting to /index.html');
            callback(null, await generateLoginSuccessfulResponse(null));
        } else {
            console.info('Authenticated, forwarding request');
            callback(null, request);
        }
    } else if (request.uri === LOGIN_ENDPOINT) {
        if ('code' in queryParams) {
            const Tokens = await getTokens(queryParams.code, lambdaHost);

            if (Tokens !== null) {
                console.info('Login successful');
                callback(null, await generateLoginSuccessfulResponse(Tokens));
            } else {
                console.info('Login failed');
                callback(null, UNAUTHORIZED_RESPONSE);
            }
        } else {
            console.info('No Auth Code supplied, forwarding to login page');
            callback(null, generateLoginResponse(lambdaHost));
        }
    } else {
        console.info('Not authenticated, redirecting to login page');
        callback(null, generateLoginResponse(lambdaHost));
    }
};

