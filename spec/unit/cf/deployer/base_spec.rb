require 'unit/spec_helper'
require 'cf/deployer/base'

module CF
  module Deployer
    describe Base do
      describe '#versions_enabled?' do
        context 'with env var set' do
          it 'returns true' do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => 'yes')
            expect(subject.versions_enabled?).to eq true
          end
        end
        context 'without env var set' do
          it 'returns false' do
            stub_const('ENV', 'CF_DEPLOYER_VERSIONS_ENABLED' => nil)
            expect(subject.versions_enabled?).to eq false
          end
        end
      end

      describe '#cf_cmd' do
        context 'when process exits successfully' do
          let(:cmd) { 'echo succeeded && exit 0' }

          it 'returns command output' do
            expect(subject.cf_cmd(cmd, true)).to include 'succeeded'
          end
        end

        context 'when process fails' do
          let(:cmd) { 'echo failed && exit 1' }

          it 'returns command output' do
            expect { subject.cf_cmd(cmd, true) }.to raise_error(/failed/)
          end
        end
      end
    end
  end
end
