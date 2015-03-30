require 'integration/spec_helper'
require 'cf/deployer/deployer'
require 'tmpdir'

module CF
  module Deployer
    describe Deployer do
      let!(:tmp_dir) { Dir.mktmpdir }
      let!(:manifest) do
        FileUtils.cp('spec/fixtures/apps.yml', "#{tmp_dir}/apps.yml")
        "#{tmp_dir}/apps.yml"
      end

      subject { Deployer.new(manifest) }

      describe '#initialize' do
        it 'sets cf home dir for an absolute path' do
          expect(Deployer.new('apps.yml', tmp_dir).cf_home).to eq tmp_dir
        end

        it 'sets the cf home path for an local path' do
          Dir.chdir(tmp_dir) do |_path|
            expect(subject.cf_home).to match tmp_dir
          end
        end

        it 'sets the manifest path for an absolute path' do
          expect(subject.manifest_path).to match "#{tmp_dir}/apps.yml$"
        end

        it 'sets the manifest path for an local path' do
          Dir.chdir(tmp_dir) do |_path|
            expect(Deployer.new('apps.yml').manifest_path).to match "#{tmp_dir}/apps.yml$"
          end
        end
      end

      describe '#cf_home_prefix' do
        it 'returns a prefix to set the CF HOME dir' do
          Dir.chdir(tmp_dir) do |_path|
            expect(subject.cf_home_prefix).to match "^(.*)#{tmp_dir}$"
          end
        end
      end
    end
  end
end
