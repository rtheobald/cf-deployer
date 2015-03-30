require 'systest/spec_helper'
require 'thread'
require 'thread_safe'
require 'rest-client'

describe 'Zero-downtime deployments' do
  context 'deploying versions of an application' do
    def cf_deploy_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'bin', 'cf_deployer'))
    end

    def cf_deploy_app_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'cf-deploy-app'))
    end

    def deploy_app(version)
      @deploying_version = version
      ENV['CF_HOME'] = cf_deploy_app_path
      ENV['CF_DEPLOYER_VERSION_NUMBER'] = version
      ENV['CF_DEPLOYER_VERSIONS_ENABLED'] = 'true'
      ENV['CF_DEPLOYER_VERSIONS_TO_KEEP'] = '3'

      commands = [
        "cd #{cf_deploy_app_path}",
        'bundle',
        "#{cf_deploy_path} cf deploy",
        "#{cf_deploy_path} cf versioning"
      ]

      puts "      --> Deploying v#{version}"
      `#{commands.join(' && ')}`
    end

    def delete_all_apps
      puts '      --> Deleting all test apps'
      delete_apps = "cd #{cf_deploy_app_path} && #{cf_deploy_path} cf apps " \
        '| egrep "cf-deploy-app" ' \
        "| awk '{print $1}' | xargs -P 15 -I {} cf d -f {}"
      `#{delete_apps}`
    end

    before(:all) do
      deploy_app('1')

      @failed_attempts     = []
      @successful_attempts = []

      curl_thread = Thread.new do
        sleep 0.1
        puts '      --> Starting new thread to assess zero-downtime'
        loop do
          begin
            RestClient.get('http://cf-deploy-app-alpha.de.a9sapp.eu')
            @successful_attempts << 1
          rescue => e
            puts "Currently deploying v#{@deploying_version}"
            puts e.inspect
            @failed_attempts << 1
          end
          sleep 2
        end
      end

      deploy_app('2')
      deploy_app('3')
      deploy_app('4')

      curl_thread.kill
    end

    after(:all) { delete_all_apps }

    let(:apps_command) { `cd #{cf_deploy_app_path} && #{cf_deploy_path} cf apps` }

    it 'does so with zero downtime' do
      expect(@failed_attempts.size).to eq 0
      expect(@successful_attempts.size).to be > 0
    end

    it 'deletes all but the last 3 versions' do
      expect(apps_command).to_not match(/cf-deploy-app-alpha-v1\s+/)
    end

    it 'removes routes from old versions of the apps' do
      expect(apps_command).to_not \
        match(/cf-deploy-app-alpha-v3 [a-z0-9 \-\/]+cf-deploy-app-alpha\./i)
    end

    it 'keeps old workers running' do
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-worker-v2\s+started/i)
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-worker-v3\s+started/i)
    end

    it 'stops old non-worker apps' do
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-scheduler-v2\s+stopped/i)
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-scheduler-v3\s+stopped/i)
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-v2\s+stopped/i)
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-v3\s+stopped/i)
    end

    it 'results in the latest being the only version with a route'  do
      expect(apps_command).to \
        match(/cf-deploy-app-alpha-v4 [a-z0-9 \-\/]+cf-deploy-app-alpha\./i)
    end
  end
end
