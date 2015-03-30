require 'unit/spec_helper'
require 'cf/deployer/version'

describe CF::Deployer do
  it 'has a version number' do
    expect(CF::Deployer::VERSION).not_to be nil
  end
end
