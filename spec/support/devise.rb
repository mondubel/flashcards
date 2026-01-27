RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Ensure Devise mappings are loaded
  config.before(:suite) do
    Rails.application.reload_routes!
  end
end
