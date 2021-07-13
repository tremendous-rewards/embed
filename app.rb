require 'sinatra'
require "sinatra/reloader"
require 'httparty'
require 'jwt'
require 'byebug'
require 'dotenv/load'
require 'securerandom'

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

# Demonstrates a reward that gets created in real time when the recipient
# chooses an option.
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
        name: "Kapil Kale",
        email: "kapil@tremendous.com"
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
  reward_id = created_order['rewards'].first['id']

  # Create the reward in real time here.
  haml :pre_created, locals: {
    tremendous_client_id: ENV['TREMENDOUS_CLIENT_ID'],
    reward_id: reward_id,
    created_order: JSON.pretty_generate(created_order)
  }
end

# The real-time implementation of the embed
# makes a POST request to this endpoint after a reward is created.
# This lets you approve the reward.
post '/approve-reward' do
  # params will look like this:
  # {
  #   jwt: "....a-very-long-string"
  # }
  jwt = JSON.parse(request.body.read)['jwt']

  # Decoded object is an array
  # first element is payload, second is header
  # [
  #   # payload
  #   {"id"=>"F2U0AIFFO6S1",
  #     "order_id"=>"L9D3T7XFE1TY",
  #     "value"=>{"denomination"=>25.0, "currency_code"=>"USD"},
  #     "delivery"=>
  #       {"method"=>"LINK",
  #        "link"=>"https://testflight.tremendous.com/rewards/payout/ldoj1dh3a",
  #        "status"=>"PENDING"},
  #     "recipient"=>
  #       {"email"=>"recipientgoeshere@gmail.com", "name"=>"Recipient Name"},
  #     "products"=>["DPIPLH0SRBO6"]},
  #
  #    # header
  #    {"typ"=>"JWT", "alg"=>"HS256"}
  #  ]
  decoded_object = JWT.decode(jwt, ENV['TREMENDOUS_API_KEY'], 'HS256')
  reward = decoded_object.first

  # This is a good place to ensure that the reward was actually meant to be created.
  # Checking against the user's email address is a good practice.

  # Approve the reward.
  # a 200 response here means that the approval was successful.
  response = TremendousAPI.post("/rewards/#{reward['id']}/approve")
  if response.ok?
    halt 200
  else
    raise "Unable to approve reward"
  end
end
