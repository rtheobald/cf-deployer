require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

namespace :spec do
  [:unit, :integration, :systest].each do |spec_type|
    desc "Run #{spec_type} tests"
    RSpec::Core::RakeTask.new(spec_type) do |t|
      t.pattern = "spec/#{spec_type}/**/*_spec.rb"
    end
  end
end

namespace :quality do
  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = true
  end
end

task default: ['quality:rubocop',
               'spec:unit',
               'spec:integration']
