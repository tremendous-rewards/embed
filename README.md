### Tremendous Embed
-----

Add flexible payouts to your application with a few lines of javascript.

### Overview

The Tremendous Embed client SDK is the easiest way to add rewards and incentives to your product, while maintaining control of your user experience.

Within your application, end-users are presented with a white-labeled interface wherein they can choose to receive funds from among a wide set of options.

### Access

You can get started immediately with your integration using our sandbox environment. First, sign up to the [Tremendous Sandbox Environment](https://testflight.tremendous.com).


### Integration


#### Add the client script to your webpage

```html
<script type="text/javascript" src="https://cdn.tremendous.com/embed/v2.0.0/client.js" />
```

#### Launch the rewards modal

```html
<div id="launchpad">Click me to redeem</div>

<script type="text/javascript">
  $(function() {
    var client = Tremendous("[TREMENDOUS_PUBLIC_KEY]", {
      domain: Tremendous.domains.SANDBOX
    });

    function redeem() {

      var request = function (method, url, data, cbk) {
        return $.ajax({
          method: method,
          url: url,
          data: data
        }).done(cbk);
      };

      client.reward.open(
        "[REWARD_JWT]",
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
          onSuccess: function(reward) {
            request("POST", "/rewards", { reward: reward }, function() {
              console.log("success")
            })
          }
        }
      );
    }

    $("#launchpad").on("click", redeem);
  });

</script>
```

### JWT

Each redeem call must include a unique JWT (json web token).  Through the JWT standard (RFC 7519), we can secure this client and ensure that the order JSON from your server is never adjusted by the front-nd.

You should create a JWT within your backend and pass it to the `reward.open` method as the first paramter.  You can find a JWT library at [https://jwt.io](https://jwt.io).

Using the Ruby JWT libray, the tokenize call looks like the following:

```ruby
  require 'jwt'

  payload = {
    recipient: {
      name: "[RECIPIENT_NAME]",  # Optional: string
      email: "[RECIPIENT_EMAIL]",  # Optional: string
    }
  }

  // We encrypt the token using our private REST access token (retrievable in the dashboard)
  token = JWT.encode(
    payload,
    "[TREMENDOUS_REST_ACCESS_TOKEN]",
    'HS256'  # Cryptographically sign with HS256 - HMAC using SHA-256 hash algorithm
  )
```

### Create vs. Retrieve Reward

Each JWT should be uniquely associated with a single reward in your system. This can be achieved by passing a unique `external_id` with each payload. For a fresh JWT which has not yet been redeemed, the embed client `reward` call will initiate a new redemption flow.

When an existing JWT is detected (a completed redemption already exists for this token), the embed client will instead open the redemption details view on the `reward` call so that your end-user can retrieve their historical information (i.e. what is the gift card code or the bank account to which I sent my funds).


#### onLoad

Triggered when the client is successfully mounted.  Passed a single config object to the handler as a parameter.

#### onSuccess

Triggered when the user completes their redemption selection. The object passed to the onSuccess handler will contain an `id` property which is the ID of the reward within the Tremendous system.

When a reward is created through the embed client, a final approval step must be taken on the backend via the REST API to activate the reward. The Reward Approval endpoint requires the ID passed back via this success callback.

[(See the REST documentation)](https://www.tremendous.com/docs).

#### onError

Triggered on any error within the client.  An error object is passed to the handler as a parameter.

#### onExit

Triggered when the user manually closes the client.


## REST API Integration

The payload to create a Reward (encrypted as a JWT) should conform to that same data structure as the REST API.

[(See the REST documentation)](https://www.tremendous.com/docs).
