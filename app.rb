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
  #  "payload"=>{
  #              "resource"=>{
  #                           "id"=>"ABCD1234EFGH",
  #                           "type"=>"orders"},
  #              "meta"=>{
  #                       "id"=>"ABCD1234EFGH",
  #                       "external_id"=>"12345678asdfghjk12345678asdfghjk",
  #                       "created_at"=>"2022-01-10T00:00:00.000Z",
  #                       "status"=>"PENDING APPROVAL",
  #                       "payment"=>{
  #                                   "subtotal"=>25.0,
  #                                   "total"=>25.0,
  #                                   "fees"=>0.0},
  #                       "rewards"=>[{
  #                                    "id"=>"1234ABCD5678",
  #                                    "order_id"=>"ABCD1234EFGH",
  #                                    "created_at"=>"2022-01-01T00:00:00.000Z",
  #                                    "value"=>{
  #                                              "denomination"=>25.0,
  #                                              "currency_code"=>"USD"},
  #                                    "delivery"=>{
  #                                                 "method"=>"LINK",
  #                                                 "link"=>"https://rewards.tremendous.com/rewards/payout/abcd12345",
  #                                                 "status"=>"PENDING"},
  #                                                 "recipient"=>{
  #                                                               "email"=>"foo-bar@example.com",
  #                                                               "name"=>"Foo Bar"}}]}}}

  body = JSON.parse(request.body.read)

  if body["event"] == "ORDERS.CREATED"
    # The resource.id from the webhook payload can be
    # used to approve the order
    order_id = body["payload"]["resource"]["id"]

    # This is a good place to ensure that the reward
    # was actually meant to be created. The order
    # data comes within the webhook payload, including
    # its rewards, amounts and recipients
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
