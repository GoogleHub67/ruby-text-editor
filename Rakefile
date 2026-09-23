require 'rspec/core/rake_task'

desc "Run the full test suite"
RSpec::Core::RakeTask.new(:test)

desc "Launch the Ruby Code++ Application"
task :run do
  ruby "notepad++.rb"
end

desc "Check code compliance via RuboCop linter"
task :lint do
  sh "bundle exec rubocop"
end

# Establish default workspace command
task default: [:test, :lint]
