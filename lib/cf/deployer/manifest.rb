require 'yaml'
require 'cf/deployer'

module CF
  module Deployer
    class Manifest < Base
      attr_reader :manifest_path

      def initialize(manifest_path = 'manifest.yml')
        @manifest_path = begin
          if File.dirname(manifest_path) == '.'
            File.expand_path("#{working_dir}/#{manifest_path}")
          else
            File.expand_path(manifest_path)
          end
        end
      end

      def prepare
        parse_manifest
        save_manifest
      end

      def target_manifest_path
        @manifest_path.gsub(/(\.ya?ml)/, '_prepared\1')
      end

      def working_dir
        File.expand_path(Dir.getwd)
      end

      def manifest_dir
        File.dirname(@manifest_path)
      end

      def manifest
        @manifest ||= YAML.load_file(@manifest_path)
      end

      def parse_manifest
        @parsed_manifest = parse_hash(manifest)
        @parsed_manifest['applications'].each_with_index do |a, i|
          @parsed_manifest['applications'][i] = parse_hash(a)
        end
        @parsed_manifest
      end

      def parse_hash(manifest_hash)
        name = manifest_hash['name']
        if versions_enabled? && name
          manifest_hash['name'] = AppVersioner.new(name).app_name_with_version
        end

        manifest_hash['path'] = manifest_dir if manifest_hash['path'] == '.'
        manifest_hash['env'].each(&parse_hash_proc(manifest_hash['env'])) if manifest_hash['env']
        manifest_hash       .each(&parse_hash_proc(manifest_hash))

        manifest_hash
      end

      def save_manifest
        File.open(target_manifest_path, 'w') do |file|
          file.write @parsed_manifest.to_yaml
        end
        target_manifest_path
      end

      def replace_placeholders(value)
        value.scan(/<<([^>>]*)>>/).flatten.compact.each do |p|
          value.gsub!("<<#{p}>>", ENV['CF_D_' + p.upcase]) if ENV['CF_D_' + p.upcase]
        end if value.respond_to?(:gsub!)
        value
      end

      def parse_hash_proc(manifest_hash)
        proc do |k, v|
          manifest_hash[k] = ENV['CF_D_' + k.upcase] || replace_placeholders(v)
        end
      end
    end
  end
end
