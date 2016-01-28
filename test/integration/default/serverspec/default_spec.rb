require 'spec_helper'

describe 'excon-cookbook::default' do
  describe file('/tmp/status') do
    its(:content) { should match /301/ }
  end
end
