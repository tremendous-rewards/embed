require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader'
require 'httparty'
require 'byebug'
require 'dotenv/load'
require 'securerandom'
require 'jwt'

# Tiny wrapper around the Tremendous API.
class TremendousAPI
  include HTTParty

  # Default to Tremendous staging.
  base_uri ENV['TREMENDOUS_API_BASE_URI'] || 'https://testflight.tremendous.com/api/v2'
  headers "Authorization" => "Bearer #{ENV['TREMENDOUS_API_KEY']}"
end

# Homepage
get '/' do
  haml :home
end

# This endpoint demonstrates rendering a reward for redemption
# that has already been created via the API.
# These gifts do not require approval.
get '/pre-created' do
  funding_source_id = TremendousAPI.get("/funding_sources").parsed_response['funding_sources'].first['id']
  product_ids = TremendousAPI.get("/products").parsed_response['products'].map{|p| p['id']}

  order = {
    payment: {
      funding_source_id: funding_source_id
    },
    reward: {
      value: {
        denomination: 5,
        currency_code: "USD",
      },
      products: product_ids,
      recipient: {
        name: "Foo Bar",
        email: "foo@bar.com"
      },
      delivery: {
        # Since we're hosting the redemption experience ourselves.
        method: "LINK"
      }
    }
  }

  # Create a reward
  response = TremendousAPI.post("/orders", body: order)
  created_order = response.parsed_response['order']

  # Fetch a reward token to use in the Embed flow (4.0.0)
  reward_id = created_order['rewards'].first['id']
  reward_embed_token = TremendousAPI.post("/rewards/#{reward_id}/generate_embed_token").dig('reward', 'token')

  # Render the reward using the Tremendous Embed flow
  haml :pre_created, locals: {
    reward_embed_token: reward_embed_token,
    created_order: JSON.pretty_generate(created_order)
  }
end

# (DEPRECATED) See the `real-time-jwt`` example instead.
# These gifts require approval.
get '/real-time' do
  funding_source_id = TremendousAPI.get("/funding_sources").parsed_response['funding_sources'].first['id']
  product_ids = TremendousAPI.get("/products").parsed_response['products'].map{|p| p['id']}
  campaign_id = TremendousAPI.get("/campaigns").parsed_response['campaigns'].first['id']

  my_external_id = SecureRandom.hex

  haml :real_time, locals: {
    tremendous_client_id: ENV['TREMENDOUS_CLIENT_ID'],
    funding_source_id: funding_source_id,
    product_ids: product_ids,
    campaign_id: campaign_id,
    my_external_id: my_external_id
  }
end

# This endpoint demonstrates rendering a reward for redemption that will be
# created in real-time. You need to encode the payload as a JWT token and sign
# it with an RSA private key. The public key must be uploaded via the APi so we
# can authorize your request.
# These gifts require approval.
get '/real-time-jwt' do
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

  # And inject both the public key pair ID (you can GET from `api/v2/public_keys`)
  # and the JWT you just encoded when rendering the front-end app.
  haml :real_time_jwt, locals: {
    key_id: public_key_id,
    jwt: jwt
  }
end

post '/approve-reward' do
  # the only parameter needed is the reward ID
  reward_id = JSON.parse(request.body.read)['reward_id']

  # query the Tremendous API for reward details
  reward_response = TremendousAPI.get("/rewards/#{reward_id}")

  # This is a good place to ensure that the reward was actually meant to be created.
  # Checking against the user's email address is a good practice.
  # To get the recipient email:
  # reward_response.parsed_response['reward']['recipient']['email']

  # if everything looks good, approve the reward
  order_id = reward_response.parsed_response['reward']['order_id']
  response = TremendousAPI.post("/orders/#{order_id}/approve")
  if response.ok?
    halt 200
  else
    raise "Unable to approve reward"
  end
end

post '/webhooks' do
  # The real-time implementation of the embed requires
  # an Order to be approved
  #
  # Youl'll need to have a webhook configured as
  # when an Order is created, a webhook event is POSTed
  # and we will handle this event. For instance:
  #
  # {"event"=>"ORDERS.CREATED",
  #  "uuid"=>"1234asdf-5678-lkjh-1209-qwertypoiu09",
  #  "created_utc"=>"2022-01-01T00:00:00.000-00:00",
  #  "payload"=>{"resource"=>{"id"=>"ABCD1234EFGH",
  #                           "type"=>"orders"},
  #              "meta"=>{"id"=>"ABCD1234EFGH",
  #                       "external_id"=>"12345678asdfghjk12345678asdfghjk",
  #                       "created_at"=>"2022-01-10T00:00:00.000Z",
  #                       "status"=>"PENDING APPROVAL",
  #                       "payment"=>{"subtotal"=>25.0,
  #                                   "total"=>25.0,
  #                                   "fees"=>0.0},
  #                       "rewards"=>[{"id"=>"1234ABCD5678",
  #                                    "order_id"=>"ABCD1234EFGH",
  #                                    "created_at"=>"2022-01-01T00:00:00.000Z",
  #                                    "value"=>{"denomination"=>25.0,
  #                                              "currency_code"=>"USD"},
  #                                    "delivery"=>{"method"=>"LINK",
  #                                                 "link"=>"https://rewards.tremendous.com/rewards/payout/abcd12345",
  #                                                 "status"=>"PENDING"},
  #                                                 "recipient"=>{"email"=>"foo-bar@example.com",
  #                                                               "name"=>"Foo Bar"}}]}}}

  body = JSON.parse(request.body.read)

  if body["event"] == "ORDERS.CREATED"
    # The resource.id from the webhook payload can be
    # used to approve the order
    order_id = body["payload"]["resource"]["id"]

    # This is a good place to ensure that the reward
    # was actually meant to be created. The order
    # data comes within the webhook payload, including
    # its rewards, amounts and recipients.
    # We'd recommend checking the email, amounts, and external_id against your database
    # to make sure this was properly authorized.
    order = body["payload"]["meta"]
    reward = order["rewards"].first
    recipient_email = reward["recipient"]["email"]
    puts recipient_email

    response = TremendousAPI.post("/orders/#{order_id}/approve")
    if response.ok?
      halt 200
    else
      raise "Unable to approve reward"
    end
  end
end
