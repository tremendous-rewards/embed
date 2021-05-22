# Documentation - Tremendous Embed

## Access

### API keys
You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).

To generate your API key, you'll navigate to Team Settings > Developers. You will need to create both an API Key and a Developer App. The `client_id` from the Developer App will be added to your client as the `TREMENDOUS_CLIENT_ID`.

![API Page](./images/sandbox-keys.png?raw=true)

Production keys are in the same place in the production environment.

### Request whitelabel access

Please contact clients@tremendous.com before starting to integrate. The Tremendous team needs to turn on a configuration for your account enabling whitelabel functionality in order for everything to work correctly.

## Required scripts
In order to render the embed, you'll need to include a link to the tremendous embed SDK. We have a hosted version on a CDN. You'll also need to add jQuery.

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v2.3.0/client.js" />

<!-- Not required if you already have jQuery available. -->
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js" />
```


## Integration

### Previously created rewards

This integration is useful when you have already created a link reward, and want the recipient to redeem on your site. It requires less configuration.

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  $(function() {
    var client = Tremendous("TREMENDOUS_CLIENT_ID", {
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {

      client.reward.open(
        // Pass in the reward_id. Note that this is different from the order_id.
        "REWARD_ID",
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
            console.log(encodedReward);
            // Approval not required.
          }
        }
      );

    }

    $("#launchpad").on("click", redeem);
  });

</script>
```


### Uncreated rewards

If you have rewards that haven't been created yet, you can create them just-in-time using the SDK. Tremendous creates the order at the moment when your recipient makes their reward selection.

This approach requires more configuration, as rewards will have to be approved by your server.

#### Create a reward in the client

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  $(function() {
    var client = Tremendous("TREMENDOUS_CLIENT_ID", {
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {
      // This payload to create a Reward in the client
      // should mirror that used in the [REST API](https://www.tremendous.com/docs).

      var order = {
        external_id: "[Some identifier that ties to the order or the reward on your server]",
        payment: {
          funding_source_id: "[YOUR_FUNDING_SOURCE_ID]",
        },
        reward: {
          value: {
            denomination: 25,
            currency_code: "USD"
          },
          campaign_id: "[OPTIONAL_CAMPAIGN_ID]",
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


#### Approving rewards

When a reward is generated using this approach, execution is paused until it is approved via the `Approve` REST endpoint. For security purposes, the ID and data for the reward is passed as an encoded JWT to prevent client side manipulation.

To fulfill the reward, you will need to complete the following steps:

1. Pass this token to your backend
2. Decode the token using your private REST access token and the SHA-256 hash algorithm (see example below)
3. Validate that the user is entitled to the reward with the given attributes (i.e. the denomination and currency code)
4. Issue a `POST` request to the [Reward Approve endpoint](https://www.tremendous.com/docs) using the Reward ID

Below is a Ruby implementation of JWT. Libraries are available in many other languages [see here](https://jwt.io/).

```ruby
  require 'jwt'

  # We encrypt the token using our private REST access token (retrievable in the dashboard)
  token = JWT.decode(
    encoded_token,
    "API_KEY",
    'HS256'  # Cryptographically sign with HS256 - HMAC using SHA-256 hash algorithm
  )
```

#### Preventing Duplication

Each reward should be uniquely associated with a single reward in your backend datastore. We would *strongly* recommend passing in a unique `external_id` for each created order. This is usually tied to some unique identifier for each reward in your codebase. We enforce uniqueness of `external_id` for all orders, which prevents duplicate redemptions.


## Events

#### `onLoad`

Triggered when the client is successfully mounted.  Passed a single config object to the handler as a parameter.

#### `onRedeem`

Triggered when the user completes their redemption selection. The argument passed to the onRedeem handler is a JWT representing the generated reward.

When a reward is created through this client, a final approval step must be taken on the backend via the REST API.

#### `onError`

Triggered on any error within the client.  An error object is passed to the handler as a parameter.

#### `onExit`

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

