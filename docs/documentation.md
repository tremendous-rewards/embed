# Documentation - Tremendous Embed

## Access

### API keys
You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).

To generate your API key, you'll navigate to Team Settings > Developers. You will need to create both an API Key and a Developer App. The `client_id` from the Developer App will be added to your client as the `TREMENDOUS_CLIENT_ID`.

![API Page](/images/sandbox-keys.png)

Production keys are in the same place in the production environment.

## Required scripts
In order to render the embed, you'll need to include a link to the tremendous embed SDK. We have a hosted version on a CDN.

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v3.0.0/client.js"/>
```


## Integration

### Previously created rewards

This integration is useful when you have already created a link reward, and want the recipient to redeem on your site. It requires less configuration.

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  document.addEventListener("DOMContentLoaded", function() {
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

    document.querySelector("a#launchpad").addEventListener("click", redeem);
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
  document.addEventListener("DOMContentLoaded", function() {
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
            console.log("It loaded");
          },
          onExit: function() {
            console.log("It closed");
          },
          onError: function(err) {
            console.log(err);
          },
          onRedeem: function() {
            console.log("Reward redeemed")
          }
        }
      );

    }

    document.querySelector("a#launchpad").addEventListener("click", redeem);
  });

</script>
```


#### Approving rewards

When a reward is generated using the "uncreated rewards" approach, execution is paused until the order is approved via the `Approve` REST endpoint. This is because the order is created by the client, and thus has the ability to be spoofed or modified before being sent to the Tremendous servers.

To fulfill the reward, you will need to complete the following steps:

1. [Create a webhook](https://developers.tremendous.com/reference/post_webhooks) to get notified when an order is placed
2. Wait for a `POST` request with an `ORDERS.CREATED` event in your [webhook](https://developers.tremendous.com/reference/webhooks-1#webhook-requests) endpoint
3. Validate that the user is entitled to the reward checking the information in `payload.meta.rewards`. Ensure that the email, reward amounts, and external_id are correct.
4. Issue a `POST` request to the [Order Approve endpoint](https://developers.tremendous.com/reference/core-orders-approve) using the Order ID in `payload.resource.id`


#### Preventing Duplication

Each order and reward should be associated with some unique identifier in your backend datastore. We would *strongly* recommend passing in a unique `external_id` for each created order that ties to that identifier. We enforce uniqueness of `external_id` for all orders, which prevents duplicate redemptions.


## Events

#### `onLoad`

Triggered when the client is successfully mounted.  Passed a single config object to the handler as a parameter.

#### `onError`

Triggered on any error within the client.  An error object is passed to the handler as a parameter.

#### `onExit`

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.
