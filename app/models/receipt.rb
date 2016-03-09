class Receipt < ActiveRecord::Base
  APPLE_METADATA_KEY_WHITELIST = %w(
    application_version
    bundle_id
    download_id
    original_purchase_date_ms
    receipt_creation_date_ms
    request_date_ms
  ).freeze

  belongs_to :user

  enum environment: {
    production: 0,
    sandbox: 1,
  }

  def self.create_from_apple_payload(payload)
    new_payload = {
      data: payload["data"],
      token: payload["token"],
      environment: environment_from_payload(payload),
      metadata: payload["receipt"].slice(*APPLE_METADATA_KEY_WHITELIST),
    }

    create(new_payload)
  end

  private

  PRODUCTION = "Production".freeze
  SANDBOX = "ProductionSandbox".freeze
  private_constant :PRODUCTION, :SANDBOX

  def self.environment_from_payload(payload)
    case payload["receipt"]["receipt_type"]
    when PRODUCTION then 0
    when SANDBOX then 1
    end
  end
  private_class_method :environment_from_payload
end
