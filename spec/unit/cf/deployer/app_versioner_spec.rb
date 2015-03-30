require 'unit/spec_helper'
require 'cf/deployer/app_versioner'
require 'tmpdir'
require 'timecop'

module CF
  module Deployer
    describe AppVersioner do
      let(:subject) { described_class.new(app_name) }

      let(:app_name) { 'foo' }

      let!(:cf_a) { File.read('spec/fixtures/cf_apps.txt') }
      let!(:cf_a_none) { File.read('spec/fixtures/cf_apps_none.txt') }
      let!(:cf_a_current_version_only) { File.read('spec/fixtures/cf_a_one_version.txt') }

      let!(:manifest_path) do
        'spec/fixtures/apps_parsed.yml'
      end

      describe '#version' do
        context 'with env var set' do
          it 'returns version' do
            stub_const('ENV', 'CF_DEPLOYER_VERSION_NUMBER' => '9999')
            expect(subject.version).to eq '9999'
          end
        end
        context 'without env var set' do
          it 'raises' do
            Timecop.freeze { expect(subject.version).to eq Time.now.to_i.to_s }
          end
        end
      end

      describe '#latest_version' do
        context 'with deployed apps' do
          before { expect(subject).to receive(:status).and_return(cf_a) }

          context 'with versions of the required app' do
            it 'returns info hash for the latest version of an app' do
              expect(subject.latest_version).to eq(name: 'foo-v20',
                                                   version: 20,
                                                   requested_state: 'started',
                                                   instances: '1/1',
                                                   memory: '128M',
                                                   disk: '1G',
                                                   urls: ['foo.de.a9sapp.eu'])
            end
          end
        end

        context 'with no deployed apps at all' do
          before { expect(subject).to receive(:status).and_return(cf_a_none) }
          it 'returns nil' do
            expect(subject.latest_version).to eq nil
          end
        end
      end

      describe '#previous_versions' do
        context 'with deployed apps' do
          it 'returns an array containing previous versions of an app' do
            expect(subject).to receive(:status).and_return(cf_a)
            expect(subject.previous_versions).to eq [
              { name: 'foo-v10', version: 10, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: ['foo.de.a9sapp.eu', 'foo-2.de.a9sapp.eu'] },
              { name: 'foo-v15', version: 15, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: ['foo.de.a9sapp.eu'] },
              { name: 'foo-v2', version: 2, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] },
              { name: 'foo-v1', version: 1, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] }
            ]
          end

          it 'returns an empty array when only one (latest) version of the app is deployed' do
            expect(subject).to receive(:status).and_return(cf_a_current_version_only)
            expect(subject.previous_versions).to eq []
          end
        end

        context 'with no deployed apps at all' do
          before { expect(subject).to receive(:status).and_return(cf_a_none) }
          it 'returns an empty array' do
            expect(subject.previous_versions).to eq []
          end
        end
      end

      describe '#deletable_versions' do
        context 'with deployed apps' do
          it 'returns an array containing apps to be deleted' do
            expect(subject).to receive(:status).and_return(cf_a)
            expect(subject.deletable_versions).to eq [
              { name: 'foo-v1', version: 1, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] },
              { name: 'foo-v2', version: 2, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] }
            ]
          end

          it 'returns an empty array when only one (latest) version of the app is deployed' do
            expect(subject).to receive(:status).and_return(cf_a_current_version_only)
            expect(subject.deletable_versions).to eq []
          end
        end

        context 'with no deployed apps at all' do
          before { expect(subject).to receive(:status).and_return(cf_a_none) }
          it 'returns an empty array' do
            expect(subject.deletable_versions).to eq []
          end
        end
      end

      describe '#delete_versions' do
        context 'with app versions' do
          let(:apps) do
            [
              { name: 'foo-v10', version: 10, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: ['foo.de.a9sapp.eu'] },
              { name: 'foo-v2', version: 2, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] },
              { name: 'foo-v1', version: 1, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] }
            ]
          end
          let(:deployer) { instance_double(Deployer) }
          it 'calls upon deletion of apps' do
            @times_called = 0
            allow(subject).to receive(:deployer).and_return(deployer)

            allow(deployer).to receive(:delete) do |app_name|
              expect(app_name).to eq apps[@times_called][:name]
              @times_called += 1
            end
            subject.delete_versions(apps)
            expect(@times_called).to eq 3
          end
        end
        context 'without any app versions' do
          let(:apps) { [] }
          it 'does not call delete' do
            expect(subject).to_not receive(:deployer)
            subject.delete_versions(apps)
          end
        end
      end

      describe '#stop_versions' do
        context 'with app versions' do
          let(:apps) do
            [
              { name: 'foo-v10', version: 10, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: ['foo.de.a9sapp.eu'] },
              { name: 'foo-v2', version: 2, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] },
              { name: 'foo-v1', version: 1, requested_state: 'started', instances: '1/1',
                memory: '128M', disk: '1G', urls: [] }
            ]
          end
          let(:deployer) { instance_double(Deployer) }
          it 'calls upon deletion of apps' do
            @times_called = 0
            allow(subject).to receive(:deployer).and_return(deployer)

            allow(deployer).to receive(:stop) do |app_name|
              expect(app_name).to eq apps[@times_called][:name]
              @times_called += 1
            end
            subject.stop_versions(apps)
            expect(@times_called).to eq 3
          end
        end
        context 'without any app versions' do
          let(:apps) { [] }
          it 'does not call stop' do
            expect(subject).to_not receive(:deployer)
            subject.delete_versions(apps)
          end
        end
      end

      describe '#unmap_app_versions' do
        context 'with app versions' do
          context 'with urls defined' do
            let(:apps) do
              [
                { name: 'foo-v10', version: 10, requested_state: 'started', instances: '1/1',
                  memory: '128M', disk: '1G', urls: ['foo.de.a9sapp.eu'] },
                { name: 'foo-v2', version: 2, requested_state: 'started', instances: '1/1',
                  memory: '128M', disk: '1G', urls: [] },
                { name: 'foo-v1', version: 1, requested_state: 'started', instances: '1/1',
                  memory: '128M', disk: '1G', urls: [] }
              ]
            end
            it 'calls upon deletion of apps' do
              @times_called = 0
              allow(subject).to receive(:cf_cmd) do |command|
                expect(command).to eq 'cf unmap-route foo-v10 de.a9sapp.eu -n foo'
                @times_called += 1
              end
              subject.unmap_app_versions(apps)
              expect(@times_called).to eq 1
            end
          end

          context 'with no urls defined' do
            let(:apps) do
              [
                { name: 'foo-v10', version: 10, requested_state: 'started', instances: '1/1',
                  memory: '128M', disk: '1G', urls: [] }
              ]
            end
            it 'calls upon deletion of apps' do
              expect(subject).to_not receive(:cf_cmd)
              subject.unmap_app_versions(apps)
            end
          end
        end

        context 'without any app versions' do
          let(:apps) { [] }
          it 'does not call cf_cmd' do
            expect(subject).to_not receive(:cf_cmd)
            subject.unmap_app_versions(apps)
          end
        end
      end

      describe '#valid_cf_client_installed?' do
        context 'with cf installed' do
          it 'returns true for 6.1.2' do
            expect(subject).to receive(:`).with('cf -v').and_return('cf version 6.1.2-6a013ca')
            expect(subject.valid_cf_client_installed?).to eq true
          end
          it 'returns false for 6.2' do
            expect(subject).to receive(:`).with('cf -v').and_return('cf version 6.2.2-6a013ca')
            expect(subject.valid_cf_client_installed?).to eq false
          end
        end
        context 'without cf installed' do
          it 'returns false' do
            expect(subject).to receive(:`).with('cf -v').and_return('-bash: cf: command not found')
            expect(subject.valid_cf_client_installed?).to eq false
          end
        end
      end
    end
  end
end
