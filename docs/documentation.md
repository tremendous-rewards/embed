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
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v3.1.0/client.js"/>
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
