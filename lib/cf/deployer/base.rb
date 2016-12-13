require 'json'
require 'yaml'
require 'open3'

module CF
  module Deployer
    class Base
      def cf_home_setup(cf_home = '.')
        @cf_home = begin
          if File.dirname(cf_home) == '.'
            File.expand_path("#{working_dir}/#{cf_home}")
          else
            File.expand_path(cf_home)
          end
        end
      end
      attr_reader :cf_home

      def working_dir
        File.expand_path(Dir.getwd)
      end

      def cf_home_prefix
        ENV['CF_HOME'] = "#{@cf_home || '.'}"
      end

      def cf_config_file_path
        "#{cf_home}/.cf/config.json"
      end

      def cf_config
        @cf_config ||= File.exist?(cf_config_file_path) && JSON.parse(IO.read(cf_config_file_path))
      end

      def logged_in?
        begin
          cf_target = cf_cmd('cf target', true)
        rescue RuntimeError
          return false
        end

        !cf_target.match(/User:\s*#{ENV['CF_LOGIN']}/).nil? &&
          !cf_target.match(/API endpoint:\s*#{ENV['CF_API']}/).nil?
      end

      def required_login_env?
        msg = "
          Please set the following environment variables;
          CF_API
          CF_LOGIN
          CF_PASSWD
          CF_ORG
          CF_SPACE
          "
        ENV['CF_API'] &&
          ENV['CF_LOGIN'] &&
          ENV['CF_PASSWD'] &&
          ENV['CF_ORG'] &&
          ENV['CF_SPACE'] || fail(msg)
      end

      def login
        return if logged_in?
        return unless required_login_env?
        cf_cmd(
          'cf login ' \
          "-u #{ENV['CF_LOGIN']} " \
          "-p #{ENV['CF_PASSWD']} " \
          "-a #{ENV['CF_API']} " \
          "-o #{ENV['CF_ORG']} "\
          "-s #{ENV['CF_SPACE']}"\
          + (ENV['CF_SKIP_SSL']?' --skip-ssl-validation':''),
          true
        )
      end

      def cf_cmd(cmd, skip_login = false)
        login unless skip_login
        cf_home_prefix
        puts "$ #{cmd.split(' ').take(2).join(' ')}"
        output, status = Open3.capture2e(cmd)

        if status.success?
          puts output
          output
        else
          fail output
        end
      end

      def status
        cf_cmd('cf apps')
      end

      def versions_enabled?
        !ENV['CF_DEPLOYER_VERSIONS_ENABLED'].nil?
      end
      VERSION_PREFIX = 'v'.freeze
      VERSION_REGEX  = /-#{VERSION_PREFIX}(\d+)\Z/.freeze

      def deployed_apps(regex = deployed_apps_regex)
        versions = []
        status_command = status.split("\n").select do |line|
          line.match(/^#{regex}-#{VERSION_PREFIX}\d+/)
        end
        status_command.each do |app_info|
          name, requested_state, instances, memory, disk, *urls = app_info.split
          versions << {
            name:            name,
            version:         app_version(name),
            requested_state: requested_state,
            instances:       instances,
            memory:          memory,
            disk:            disk,
            urls:            urls.each(&method(:remove_trailing_commas))
          }
        end
        versions
      end

      def app_version(name)
        name.match(VERSION_REGEX)[1].to_i
      end

      def remove_trailing_commas(string)
        string.gsub!(/,$/, '')
      end
    end
  end
end
