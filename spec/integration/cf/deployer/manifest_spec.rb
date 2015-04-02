require 'integration/spec_helper'
require 'cf/deployer/manifest'
require 'tmpdir'
require 'timecop'

module CF
  module Deployer
    describe Manifest do
      let(:tmp_dir) do
        File.expand_path(Dir.mktmpdir)
      end
      let(:manifest) do
        FileUtils.cp('spec/fixtures/apps.yml', "#{tmp_dir}/apps.yml")
        "#{tmp_dir}/apps.yml"
      end

      subject do
        Manifest.new(manifest)
      end

      describe '#initialize' do
        it 'sets the manifest path for an absolute path' do
          expect(subject.manifest_path).to match "#{tmp_dir}/apps.yml$"
        end
        it 'sets the manifest path for an local path' do
          Dir.chdir(tmp_dir) do |_path|
            expect(Manifest.new('apps.yml').manifest_path).to match "#{tmp_dir}/apps.yml$"
          end
        end
      end

      describe '#manifest_dir' do
        it 'returns the directory of the manifest' do
          expect(subject.manifest_dir).to match tmp_dir
        end
        it 'returns the directory of the manifest for a local path' do
          Dir.chdir(tmp_dir) do |_path|
            expect(Manifest.new('apps.yml').manifest_dir).to match tmp_dir
          end
        end
      end

      describe '#manifest' do
        it 'loads a manifest as a hash' do
          expect(subject.manifest).to include 'path' => '.', 'memory' => '128M'
        end
      end

      describe '#parse_manifest' do
        context 'without versions' do
          it 'parses a manifest with no overrides' do
            stub_const('ENV', {})
            expect(subject.parse_manifest).to include 'instances' => 1
          end

          it 'parses a manifest with overrides' do
            stub_const('ENV', 'CF_D_MEMORY' => '256M', 'CF_D_BAR_URL' => 'https://foo.com')
            expect(subject.parse_manifest).to include 'memory' => '256M'
            expect(subject.parse_manifest['applications'].first['env']).to \
              include 'BAR_URL' => 'https://foo.com'
          end

          it 'parses placeholders in elements' do
            stub_const('ENV', 'CF_D_BUILD_NUMBER' => '999')
            expect(subject.parse_manifest['applications'].first['host']).to eq 'foo-999'
            expect(subject.parse_manifest['applications'].first['env']['BAR_URL']).to eq 'foo-999'
          end

          it 'provides a full path to the application' do
            expect(subject.parse_manifest['path']).to eq tmp_dir
          end
        end

        context 'with versions' do
          before do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => 'true')
          end

          it 'parses a manifest with overrides' do
            Timecop.freeze do
              expect(subject.parse_manifest['applications'].first['name']).to \
                eq "foo-v#{Time.now.to_i}"
            end
          end
        end

        context 'with versions and a overriden name' do
          before do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => 'true',
                              'CF_D_NAME' => 'bar-production')
          end

          it 'parses a manifest with overrides' do
            Timecop.freeze do
              expect(subject.parse_manifest['applications'].first['name']).to \
                eq "bar-production-v#{Time.now.to_i}"
            end
          end
        end
      end

      describe '#save_manifest' do
        it 'saves a manifest for an absolute path' do
          expect(subject.save_manifest).to match "#{tmp_dir}/apps_prepared.yml$"
          expect(File.exist?(subject.save_manifest)).to eq true
        end
        it 'saves a manifest for an local path' do
          Dir.chdir(tmp_dir) do |_path|
            path = Manifest.new('apps.yml').save_manifest
            expect(path).to match "#{tmp_dir}/apps_prepared.yml$"
            expect(File.exist?(path)).to eq true
          end
        end
      end
    end
  end
end
