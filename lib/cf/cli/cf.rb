# Encoding: utf-8
require 'cf/cli/base'
require 'cf/deployer'

module CF
  module CLI
    class Cf < Base
      desc 'prepare MANIFEST_PATH', 'Prepare a CF manifest'
      def prepare(manifest_path = './manifest.yml')
        CF::Deployer::Manifest.new(manifest_path).prepare
      end

      desc 'push MANIFEST_PATH', 'Push an app to CF'
      def push(manifest_path = './manifest_prepared.yml')
        deployer = CF::Deployer::Deployer.new(manifest_path)
        deployer.retriable_push
        puts deployer.status
      end

      desc 'deploy MANIFEST_PATH', 'Deploy to CF'
      def deploy(manifest_path = './manifest.yml')
        prepare(manifest_path)
        push(manifest_path.sub('manifest.yml', 'manifest_prepared.yml'))
      end

      desc 'login', 'Login to CF'
      def login
        deployer.login
      end

      desc 'apps', 'Apps deployed in current CF'
      def apps
        login
        deployer.status
      end

      desc 'delete', 'Delete a CF app'
      def delete(app_name)
        login
        deployer.delete(app_name)
      end

      desc 'stop', 'Stop a CF app'
      def stop(app_name)
        login
        deployer.stop(app_name)
      end

      desc 'versioning', 'Remove old apps and stop old scheduler jobs'
      def versioning(manifest_path = './manifest_prepared.yml')
        login
        deployer = CF::Deployer::Deployer.new(manifest_path)
        deployer.versioning
      end

      private

      def deployer
        @deployer ||= CF::Deployer::Deployer.new
      end
    end
  end
end
