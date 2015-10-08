require 'spec_helper'
describe 'standalone_swift' do

  context 'with defaults for all parameters' do
    it { should contain_class('standalone_swift') }
  end
end
