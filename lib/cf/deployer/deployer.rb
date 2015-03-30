require 'retryable'

require_relative 'base'

module CF
  module Deployer
    class Deployer < Base
      attr_reader :manifest_path

      def initialize(manifest_path = '.', cf_home = '.')
        cf_home_setup(cf_home)
        @manifest_path = begin
          if File.dirname(manifest_path) == '.'
            File.expand_path("#{working_dir}/#{manifest_path}")
          else
            File.expand_path(manifest_path)
          end
        end
      end

      def retriable_push
        retryable(tries: 3, exception_cb: proc { |_| delete_manifest_apps }) { push }
      end

      def push
        cf_cmd("cf push -f #{manifest_path}")
      end

      def delete(app_name)
        cf_cmd("cf delete -f #{app_name}")
      end

      def stop(app_name)
        cf_cmd("cf stop #{app_name}")
      end

      def versioning
        versioner.wait_for_new_version_started
        versioner.delete_deletable_apps
        versioner.unmap_previous_apps
        versioner.stop_previous_non_workers
      end

      def versioner
        @versioner ||= Versioner.new(manifest_path)
      end

      def delete_manifest_apps
        versioner.each_app(&method(:delete))
      end
    end
  end
end
