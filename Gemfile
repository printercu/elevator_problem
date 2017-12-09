lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'celluloid', '0.17.3'

group :pry do
  gem 'awesome_print', '1.8.0'
  gem 'byebug', '9.1.0', platform: %i[mri]
  gem 'pry', '0.11.2'
  gem 'pry-byebug', '3.5.0', platform: %i[mri]
  gem 'pry-doc', '0.11.1'
end

group :development do
  gem 'gemfile_locker', '0.2.0', require: false
  gem 'rubocop', '0.51.0', require: false
end

group :development, :test do
  gem 'bundler', '~> 1.16', require: false
  gem 'rake', '~> 10.0', require: false
  gem 'rspec', '3.7.0'
  gem 'rspec-its', '1.2.0'
end
