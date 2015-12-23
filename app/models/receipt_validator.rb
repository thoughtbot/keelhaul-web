require "faraday_middleware"

class ReceiptValidator
  def initialize(payload:, user:, sandbox: "0")
    @payload = payload
    @user = user
    @sandbox = sandbox
  end

  def validate
    if new_receipt?
      response = post
      validation = Response.for(response.body)
      validation.on_success { create_receipt(response.body) }
    elsif mismatching_environment?
      Response::BadRequestError.new
    elsif token_matches?
      Response::SuccessfulRequest.new(matching_receipt.metadata)
    else
      Response::UnauthenticatedError.new
    end
  end

  private

  attr_reader :payload, :user, :sandbox

  def post
    connection.post do |request|
      request.headers["Content-Type"] = "application/json"
      request.body = JSON.dump("receipt-data" => payload[:data])
    end
  end

  def connection
    Faraday.new(apple_url) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def apple_url
    AppleReceipt.endpoint_url(sandbox: sandbox)
  end

  def new_receipt?
    !matching_receipt
  end

  def mismatching_environment?
    matching_receipt.environment != current_environment
  end

  def token_matches?
    matching_receipt.token == payload[:token]
  end

  def matching_receipt
    @_matching_receipt ||= user.receipts.find_by(data: payload[:data].to_s)
  end

  def create_receipt(json)
    user.receipts.create_from_apple_payload(
      json.merge("data" => payload[:data], "token" => payload[:token]),
    )
  end

  def current_environment
    AppleReceipt.environment(sandbox: sandbox)
  end
end
