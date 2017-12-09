require 'bundler/setup'
Bundler.require(:test)

require 'elevator_problem'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.alias_example_to :scenario

  config.around celluloid: true do |ex|
    begin
      Celluloid.shutdown
      Celluloid.boot
      ex.run
    ensure
      Celluloid.shutdown
      Celluloid.boot
    end
  end
end
