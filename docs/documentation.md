# Documentation - Tremendous Embed

## Access

> [!NOTE]
> The embed flow requires review and approval by Tremendous. Please reach out if you're planning on integrating.

### API keys

You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).

To generate your API key, you'll navigate to Team Settings > Developers.

![API Page](/images/sandbox-keys.png)

Production keys are in the same place in the production environment.

## Required scripts

In order to render the embed, you'll need to include a link to the Tremendous Embed SDK. We have a hosted version on a CDN.

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/4.1.0/client.js"/>
```

## Integration

This integration is useful when you have already created a link reward, and want the recipient to redeem on your site.

The embed flow uses reward tokens that are only valid for 24h. These tokens can be generated using the [generate_embed_token](https://developers.tremendous.com/reference/generate-reward-token) endpoint from the Tremendous API. It fetches a new temporary token to be passed along to the frontend. These tokens shouldn't be permanently stored. Using a temporary token that is past its expiry date will result in an error.

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
            console.log("Loaded");
          },
          onExit: function() {
            console.log("Closed");
          },
          onError: function(err) {
            console.log(err);
          },
          onRedeem: function(rewardId, orderId) {
            console.log("Redeemed", rewardId, orderId);
          }
        }
      );
    }

    document.querySelector("a#launchpad").addEventListener("click", redeem);
  });
</script>
```

### Uncreated rewards

If you have rewards that have yet to be created, you can create them just-in-time using the Embed SDK. Tremendous creates the order at the moment when your recipient makes their reward selection.

This approach requires more configuration, as you must create a pair of asymmetric key, encode your payload, and [approve the order](https://developers.tremendous.com/reference/approve-order). You encode your order payload as an RS256 JWT and sign it with your private key. Tremendous verifies the payload using your public key.

You can update your public key using the [public_keys](https://developers.tremendous.com/reference/create-public-key) endpoint from the Tremendous API.

#### Create a reward in the client

You can do something like this to encode your payload (rails example):

```ruby
  funding_source_id = TremendousAPI.get("/funding_sources").parsed_response['funding_sources'].first['id']
  public_key_id = TremendousAPI.get("/public_keys").parsed_response['public_keys'].last['id']
  campaign_id = TremendousAPI.get("/campaigns").parsed_response['campaigns'].first['id']

  # Instantiate an OpenSSL RSA private key object
  private_key = OpenSSL::PKey::RSA.new(File.read('tremendous_key.pem'))

  # Use the private key object to encode the whole payload and sign it
  jwt = JWT.encode({
    countries: ["US"],
    external_id: "#{SecureRandom.hex}",
    payment: {
      funding_source_id: funding_source_id,
    },
    reward: {
      campaign_id: campaign_id,
      value: {
        denomination: 10,
        currency_code: "USD"
      },
      recipient: {
        name: "Foo Bar",
        email: "foo@bar.com"
      }
    }
  }, private_key, 'RS256')
```

That generates a RS256 signed JWT token to be passed along to the frontend. Once the temporary token is fetched, you can pass it to the Embed SDK to start the redemption flow:

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  document.addEventListener("DOMContentLoaded", function() {
    var client = Tremendous({
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {
      // The JWT encoded payload should mirror the Order payload
      // used in the [REST API](https://www.tremendous.com/docs).
      var order = {
        key_id: "[YOUR_PUBLIC_KEY_ID]",
        jwt: "[Order payload, JWT encoded, and signed with your private key]",
      };

      client.reward.create(order, {
        onLoad: function() {
          console.log("Loaded");
        },
        onExit: function()) {
          console.log("Closed");
        },
        onError: function(err) {
          console.log(err);
        },
        onRedeem: function(rewardId, orderId) {
          console.log("Redeemed", rewardId, orderId);
        }
      });
    }

    document.querySelector("a#launchpad").addEventListener("click", redeem);
  });
</script>
```

#### Approving rewards

When a reward is generated using the "uncreated rewards" approach, execution is paused until the order is approved via the `approve` REST endpoint.

To fulfill the reward, there are two possible approaches:

##### Using the `onRedeem` callback (recommended)

1. Capture the `rewardId` received on the `onRedeem` callback that you provided to `client.reward.create`, which is triggered after the user redeems the reward, and send it to your server.
2. On the server, make a `GET` request to the [rewards endpoint](https://developers.tremendous.com/reference/core-rewards-show) using the `rewardId`.
3. Validate that the user is entitled to the reward checking the response payload.
4. Issue a `POST` request to the [Order Approve endpoint](https://developers.tremendous.com/reference/core-orders-approve) using the `order_id` from the response payload.

##### Using Webhooks

1. [Create a webhook](https://developers.tremendous.com/reference/post_webhooks) to get notified when an order is placed
2. Wait for a `POST` request with an `ORDERS.CREATED` event in your [webhook](https://developers.tremendous.com/reference/webhooks-1#webhook-requests) endpoint
3. Validate that the user is entitled to the reward checking the information in `payload.meta.rewards`.
4. Issue a `POST` request to the [Order Approve endpoint](https://developers.tremendous.com/reference/core-orders-approve) using the Order ID in `payload.resource.id`

#### Adding custom fields

If you ever need to add custom data to a reward, check the [API documentation](https://developers.tremendous.com/reference/using-custom-fields-to-add-custom-data-to-rewards) and add `custom_fields` to the `reward` object as described in there. Then, encode the whole `order` payload as a JWT as above.

#### Preventing duplication

Each order and reward should be associated with some unique identifier in your backend datastore. We would *strongly* recommend passing in a unique `external_id` for each created order that ties to that identifier. We enforce the uniqueness of `external_id` for all orders, which prevents duplicate redemptions.

## Events

### `onLoad`

Triggered when the client is successfully mounted. Passed a single config object to the handler as a parameter.

### `onError`

Triggered on any error within the client. An error object is passed to the handler as a parameter.

### `onExit`

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

### `onRedeem`

Triggered when the user confirms the redemption of the reward.
