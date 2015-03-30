require 'cf/deployer'
require 'timeout'

module CF
  module Deployer
    class Versioner < Base
      def initialize(manifest_path)
        @manifest_path = manifest_path
      end
      attr_reader :manifest_path

      def unmap_previous_apps
        return unless versions_enabled?
        manifest_apps.each do |app|
          versioner = AppVersioner.new(unversioned_app_name(app['name']))
          versioner.unmap_app_versions(versioner.previous_versions)
        end
      end

      def delete_deletable_apps
        return unless versions_enabled?
        manifest_apps.each do |app|
          versioner = AppVersioner.new(unversioned_app_name(app['name']))
          versioner.delete_versions(versioner.deletable_versions)
        end
      end

      def wait_for_new_version_started
        return unless versions_enabled?
        Timeout.timeout(1_200) do
          loop do
            manifest_apps_regex = Regexp.union(manifest_apps
                                  .map { |app| unversioned_app_name(app['name']) })
            apps_deployed       = deployed_apps(manifest_apps_regex)

            latest_running_apps = apps_deployed.group_by { |app| unversioned_app_name(app[:name]) }
                                  .map do |_app_name, apps_group|
                                    apps_group.max { |a, b| a[:version] <=> b[:version] }
                                  end

            # #to_i disregards first non-integer character, so '1/2' becomes 1, '0/1' becomes 0, etc
            return true unless latest_running_apps.map { |app| app[:instances].to_i }.include?(0)
            sleep 5
          end
        end
      end

      def stop_previous_non_workers
        return unless versions_enabled?
        manifest_apps.select { |app| !app['name'].match(/-worker/) }.each do |app|
          versioner = AppVersioner.new(unversioned_app_name(app['name']))
          versioner.stop_versions(versioner.previous_versions)
        end
      end

      def each_app
        manifest_apps.each do |app|
          yield app['name']
        end
      end

      private

      def manifest
        @manifest ||= YAML.load_file(manifest_path)
      end

      def manifest_apps
        manifest['applications']
      end

      def unversioned_app_name(app_name)
        app_name.tap { |name| name.gsub!(VERSION_REGEX, '') }
      end
    end
  end
end
