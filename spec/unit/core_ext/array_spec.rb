require 'spec_helper'
require 'core_ext/array'

describe Array do
  subject do
    [
      { name: 'app1', version: 1 },
      { name: 'app2', version: 2 },
      { name: 'app4', version: 4 },
      { name: 'app3', version: 3 }
    ]
  end

  describe '#latest_version' do
    it 'returns the latest version only' do
      expect(subject.latest_version).to eq(name: 'app4', version: 4)
    end
  end

  describe '#sort_by_version' do
    it 'sorts array by version' do
      expect(subject.sort_by_version).to eq [
        { name: 'app1', version: 1 },
        { name: 'app2', version: 2 },
        { name: 'app3', version: 3 },
        { name: 'app4', version: 4 }
      ]
    end
  end
end
