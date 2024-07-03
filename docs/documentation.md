# Documentation - Tremendous Embed

## Access

> [!NOTE]
> The Embed flow requires review and approval by Tremendous. Please reach out if you're planning on integrating.

### API keys
You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).

To generate your API key, you'll navigate to Team Settings > Developers.
![API Page](/images/sandbox-keys.png)

Production keys are in the same place in the production environment.

## Required scripts
In order to render the embed, you'll need to include a link to the tremendous embed SDK. We have a hosted version on a CDN.

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v4.0.0/client.js"/>
```


## Integration

This integration is useful when you have already created a link reward, and want the recipient to redeem on your site.

The Embed flow uses reward tokens that are only valid for 24h.
These tokens can be generated using the [generate_embed_token](https://developers.tremendous.com/reference/generate-reward-token) endpoint from the Tremendous API.

As an example on how to fetch a token, you can navigate to [app.rb](https://github.com/tremendous-rewards/embed/blob/master/app.rb) in this demo app, where you'll find:

```ruby
# Fetch a reward token to use in the Embed flow
reward_id = created_order['rewards'].first['id']
reward_embed_token = TremendousAPI.post("/rewards/#{reward_id}/generate_embed_token").dig('reward', 'token')
```

That makes the API call in the backend, using your own API key, and fetches a new temporary token to be passed along to the frontend.
These tokens shouldn't be permanently stored. Using a temporary token that is past its expiry date will result in an error.

Once the temporary token is fetched, you can pass it to the Embed SDK to start the redemption flow.

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  document.addEventListener("DOMContentLoaded", function() {
    var client = Tremendous({
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {

      client.reward.open(
        // Pass in the temporary reward token.
        // Note that this is different from the reward_id and the order_id.
        "REWARD_EMBED_TOKEN",
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
          onRedeem: function(rewardId, orderId) {
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

If you have rewards that haven't been created yet, you can create them just-in-time using the SDK.
Tremendous creates the order at the moment when your recipient makes their reward selection.

If you ever need to add custom data to a reward, please check the [API documentation](https://developers.tremendous.com/reference/using-custom-fields-to-add-custom-data-to-rewards) and add `custom_fields` to the
`reward` object as described in there.

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
          onRedeem: function(rewardId, orderId) {
            console.log(`Reward redeemed: ${rewardId}. Order ID: ${orderId}`)
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

To fulfill the reward, there are two possible approaches:

##### Using the `onRedeem` callback (recommended)

1. Capture the `rewardId` received on the `onRedeem` callback that you provided to `client.reward.create`, which is triggered after the user redeems the reward, and send it to your server.
2. On the server, make a `GET` request to the [rewards endpoint](https://developers.tremendous.com/reference/core-rewards-show) using the `rewardId`.
3. Validate that the user is entitled to the reward checking the response payload.
4. Issue a `POST` request to the [Order Approve endpoint](https://developers.tremendous.com/reference/core-orders-approve) using the `order_id` from the response payload.

##### Using Webhooks

1. [Create a webhook](https://developers.tremendous.com/reference/post_webhooks) to get notified when an order is placed
2. Wait for a `POST` request with an `ORDERS.CREATED` event in your [webhook](https://developers.tremendous.com/reference/webhooks-1#webhook-requests) endpoint
3. Validate that the user is entitled to the reward checking the information in `payload.meta.rewards`. Ensure that the email, reward amounts, and external_id are correct.
4. Issue a `POST` request to the [Order Approve endpoint](https://developers.tremendous.com/reference/core-orders-approve) using the Order ID in `payload.resource.id`

#### Preventing Duplication

Each order and reward should be associated with some unique identifier in your backend datastore. We would *strongly* recommend passing in a unique `external_id` for each created order that ties to that identifier. We enforce uniqueness of `external_id` for all orders, which prevents duplicate redemptions.


## Events

### `onLoad`

Triggered when the client is successfully mounted. Passed a single config object to the handler as a parameter.

### `onError`

Triggered on any error within the client. An error object is passed to the handler as a parameter.

### `onExit`

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

### `onRedeem`

Triggered when the user confirms the redemption of the reward.
