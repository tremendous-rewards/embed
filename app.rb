require 'sinatra'
require "sinatra/reloader"
require 'httparty'
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

  # Fetch a reward token to use in the Embed flow
  reward_id = created_order['rewards'].first['id']
  reward_embed_token = TremendousAPI.post("/rewards/#{reward_id}/generate_embed_token").dig('reward', 'token')

  # Render the reward using the Tremendous Embed flow
  haml :pre_created, locals: {
    reward_embed_token: reward_embed_token,
    created_order: JSON.pretty_generate(created_order)
  }
end
