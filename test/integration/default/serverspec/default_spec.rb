require 'spec_helper'

describe 'excon-cookbook::default' do
  describe file('/tmp/status') do
    its(:content) { should match /200/ }
  end
end
