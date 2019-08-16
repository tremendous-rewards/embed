### Tremendous Embed
-----

### Overview

The Tremendous Embed client SDK is the easiest way to add rewards and incentives to your product, while maintaining control of your user experience. Within your application, end-users are presented with a white-labeled interface wherein they can choose to receive funds from among a wide set of options.

### Access

You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com) to grab your API access tokens.


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

The payload to create a Reward should conform to that same data structure as the REST API.

[Check out the REST docs](https://www.tremendous.com/docs)


### JWT encoded reward

When a reward is generated on the front end, execution is paused until it is approved
via the `Approve` REST endpoint.

For security purposes, the ID and data for the reward is passed as an encoded JWT to prevent client side manipulation.

To fulfill the reward, you will need to complete the following steps:

1. Pass this token to your backend
2. Decode the token using your private REST access token and the SHA-256 hash algorithm (see example below)
3. Validate that the user is entitled to the reward with the given attributes (i.e. the denomination and currency code)
4. Issue a `POST` request to the [Reward Approve endpoint](https://www.tremendous.com/docs) using the Reward ID


Below is a Ruby implementation of JWT.

```ruby
  require 'jwt'

  // We encrypt the token using our private REST access token (retrievable in the dashboard)
  token = JWT.decode(
    token,
    "[TREMENDOUS_REST_ACCESS_TOKEN]",
    'HS256'  # Cryptographically sign with HS256 - HMAC using SHA-256 hash algorithm
  )
```

### Prevent Duplication

Each JWT should be uniquely associated with a single reward in your system. This can be achieved by passing a unique `external_id` with each payload.


#### onLoad

Triggered when the client is successfully mounted.  Passed a single config object to the handler as a parameter.

#### onRedeem

Triggered when the user completes their redemption selection. The object passed to the onRedeem handler will contain an `id` property which is the ID of the reward within the Tremendous system.

When a reward is created through the embed client, a final approval step must be taken on the backend via the REST API to activate the reward. The Reward Approval endpoint requires the ID passed back via this success callback.

[Check out the REST docs](https://www.tremendous.com/docs)

#### onError

Triggered on any error within the client.  An error object is passed to the handler as a parameter.

#### onExit

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

