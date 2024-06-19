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

## Events

### `onLoad`

Triggered when the client is successfully mounted. Passed a single config object to the handler as a parameter.

### `onError`

Triggered on any error within the client. An error object is passed to the handler as a parameter.

### `onExit`

Triggered when the user manually closes the redemption screen or when the SDK programmatically does so through the `reward.close` method.

### `onRedeem`

Triggered when the user confirms the redemption of the reward.
