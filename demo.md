# Demo Application - Tremendous Embed

Included is a small Ruby application showcasing the embed.

## Setup

1. First, clone down the repo.


2. Add your API keys

Visit the [Tremendous Sandbox](https://testflight.tremendous.com) to get your API key and client id.
![Developer dash](./sandbox.jpg?raw=true)

Then add them to `.env`. This file will populate your keys as environment variables for the application.

You will not need the client_secret (your api key will function as the secret).

```sh
$ touch .env
$ echo TREMENDOUS_CLIENT_ID=your-client-id >> .env
$ echo TREMENDOUS_API_KEY=your-api-key >> .env
$ # make sure it looks right
$ cat .env
```

3. Install dependencies

```sh
$ bundle install
$ ruby app.rb
```

And then visit `localhost:4567` in your browser.
