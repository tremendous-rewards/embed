# Demo Application - Tremendous Embed

Included is a small Ruby application showcasing the embed.

## Setup

1. Clone this repo

```sh
$ git clone git@github.com:tremendous-rewards/embed.git
```

2. Add your API keys

Visit the [Tremendous Sandbox](https://testflight.tremendous.com) to get your API key and client id, and them to `.env`. This file will populate your keys as environment variables for the application.

```sh
$ touch .env
$ echo TREMENDOUS_CLIENT_ID=your-client-id >> .env
$ echo TREMENDOUS_API_KEY=your-api-key >> .env
$ # make sure it looks right
$ cat .env
```

Note: you will not need the client_secret (your api key will function as the secret).

3. Install dependencies

Make sure you have Ruby installed, or [add it using these instructions](https://www.ruby-lang.org/en/documentation/installation/).

Then:

```sh
$ bundle install
$ ruby app.rb
```

4. Visit `localhost:4567` in your browser
