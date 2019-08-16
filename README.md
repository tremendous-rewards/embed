### Tremendous Embed
-----

### Overview

The Tremendous Embed SDK is the easiest way to add rewards and incentives to your application, while maintaining control of your user experience. Within your application, end-users are presented with a white-labeled interface wherein they can choose to receive funds from among a wide catalog of options (.

### Access

You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).

To generate your tokens, you'll navigate to Settings > API.  You will need to generate both a REST API Key and a Developer App to grab your public key which you will add to the client as the `TREMENDOUS_PUBLIC_DEVELOPER_KEY`.

![API Page](./sandbox.png?raw=true)

### Integration


#### Add the client script to your webpage

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v2.1.0/client.js" />
```

#### Launch the rewards modal

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  $(function() {
    var client = Tremendous("[TREMENDOUS_PUBLIC_DEVELOPER_KEY]", {
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {

      var order = {
        payment: {
          funding_source_id: "[YOUR_FUNDING_SOURCE_ID]",
        },
        reward: {
          value: {
            denomination: 25,
            currency_code: "USD"
          },
          products: "[Array of products available such as Amazon, Visa, etc. (see products REST endpoint)]",
          recipient: {
            name: "Recipient Name",
            email: "recipientgoeshere@gmail.com"
          }
        }
      }

      client.reward.create(
        order,
        {
          onLoad: function() {
            console.log("It Loaded");
          },
          onExit: function() {
            console.log("It Closed");
          },
          onError: function(err) {
            console.log(err);
          },
          onRedeem: function(encodedReward) {
            // Send this JWT encoded token to backend
            // decode it and approve the reward via the APPROVE REST endpoint.
            console.log(encodedReward);
          }
        }
      );

    }

    $("#launchpad").on("click", redeem);
  });

</script>
```

## Reward Create Parameters

The payload to create a Reward in the client should mirror that used in the [REST API](https://www.tremendous.com/docs).


### JWT encoded reward

When a reward is generated on the front end, execution is paused until it is approved
via the `Approve` REST endpoint. For security purposes, the ID and data for the reward is passed as an encoded JWT to prevent client side manipulation.

To fulfill the reward, you will need to complete the following steps:

1. Pass this token to your backend
2. Decode the token using your private REST access token and the SHA-256 hash algorithm (see example below)
3. Validate that the user is entitled to the reward with the given attributes (i.e. the denomination and currency code)
4. Issue a `POST` request to the [Reward Approve endpoint](https://www.tremendous.com/docs) using the Reward ID


Below is a Ruby implementation of JWT. Libraries are available in many other languages [see here](https://jwt.io/).

```ruby
  require 'jwt'

  // We encrypt the token using our private REST access token (retrievable in the dashboard)
  token = JWT.decode(
    encoded_token,
    "[TREMENDOUS_REST_ACCESS_TOKEN]",
    'HS256'  # Cryptographically sign with HS256 - HMAC using SHA-256 hash algorithm
  )
```

### Prevent Duplication

Each reward should be uniquely associated with a single reward in your backend datastore. To prevent any possible duplication, this can be achieved by passing a unique `external_id` with each order payload.


#### onLoad

Triggered when the client is successfully mounted.  Passed a single config object to the handler as a parameter.

#### onRedeem

Triggered when the user completes their redemption selection. The argument passed to the onRedeem handler is a JWT representing the generated reward.

When a reward is created through this client, a final approval step must be taken on the backend via the REST API.

#### onError

Triggered on any error within the client.  An error object is passed to the handler as a parameter.

#### onExit

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

