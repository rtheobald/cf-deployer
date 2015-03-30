require 'unit/spec_helper'
require 'cf/deployer/versioner'

module CF
  module Deployer
    describe Versioner do
      let(:app_versioner) { instance_double(AppVersioner) }
      let(:manifest_apps) { [{ 'name' => 'foo' }] }

      subject { Versioner.new('.') }

      before do
        allow(subject).to receive(:manifest_apps).and_return(manifest_apps)
        expect(AppVersioner).to receive(:new).with('foo').and_return(app_versioner)
      end

      describe '#unmap_previous_apps' do
        context 'with versions enabled' do
          before do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => 'yes')
            expect(app_versioner).to receive(:unmap_app_versions).with(app_versions)
            expect(app_versioner).to receive(:previous_versions).and_return(app_versions)
          end

          context 'with apps to unmap' do
            let(:app_versions) { [{ name: 'foo-v123' }] }
            it 'unmaps each liable app' do
              subject.unmap_previous_apps
            end
          end
          context 'with only apps to be kept' do
            let(:app_versions) { [] }
            it 'does not unmap any apps' do
              subject.unmap_previous_apps
            end
          end
        end
      end

      describe '#delete_deletable_apps' do
        context 'with versions enabled' do
          before do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => 'yes')
            expect(app_versioner).to receive(:delete_versions).with(app_versions)
            expect(app_versioner).to receive(:deletable_versions).and_return(app_versions)
          end

          context 'with deleteable apps' do
            let(:app_versions) { [{ name: 'foo-v123' }] }
            it 'deletes each deletable app' do
              subject.delete_deletable_apps
            end
          end
          context 'with only apps to be kept' do
            let(:app_versions) { [] }
            it 'does not delete any apps' do
              subject.delete_deletable_apps
            end
          end
        end
      end
    end
  end
end
