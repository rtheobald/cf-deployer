require 'core_ext/array'
require 'cf/deployer'

module CF
  module Deployer
    class AppVersioner < Base
      VERSIONS_TO_KEEP = (ENV['CF_DEPLOYER_VERSIONS_TO_KEEP'] || 3).to_i.freeze

      def initialize(app_name, cf_home = '.')
        cf_home_setup(cf_home)
        @app_name = app_name
      end
      attr_reader :app_name
      alias_method :deployed_apps_regex, :app_name

      def version
        @version ||= (ENV['CF_DEPLOYER_VERSION_NUMBER'] || Time.now.to_i.to_s)
      end

      def app_name_with_version
        "#{app_name}-#{VERSION_PREFIX}#{version}"
      end

      def latest_version
        deployed_apps.latest_version
      end

      def previous_versions
        versions = deployed_apps
        versions.delete(versions.latest_version)
        versions
      end

      def deletable_versions
        versions = deployed_apps.sort_by_version
        versions.pop(VERSIONS_TO_KEEP)
        versions
      end

      def unmap_app_versions(app_versions)
        app_versions.each do |app|
          app[:urls].each do |url|
            cf_cmd("cf unmap-route #{app[:name]} " \
                    "#{app_domain(url)} " \
                    "-n #{app_host(url)}")
          end
        end
      end

      def delete_versions(app_versions)
        app_versions.each do |app|
          deployer.delete(app[:name])
        end
      end

      def stop_versions(app_versions)
        app_versions.each do |app|
          deployer.stop(app[:name])
        end
      end

      def valid_cf_client_installed?
        !(`cf -v` =~ /cf version 6\.1\.2/).nil?
      end

      private

      def app_domain(url)
        url.match(/\A[^\.]+\.(.+)\Z/i)[1]
      end

      def app_host(url)
        url.match(/\A([^\.]+)/i)[1]
      end

      def deployer
        @deployer ||= CF::Deployer::Deployer.new
      end
    end
  end
end
