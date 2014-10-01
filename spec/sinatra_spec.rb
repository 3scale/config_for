require 'sinatra/base'
require 'config_for/sinatra'

RSpec.describe ConfigFor::Sinatra do
  it { expect(Sinatra::Application.extensions).to include(described_class) }
end

RSpec.describe Sinatra::Application do
  subject(:application) { Sinatra::Application }
  let(:settings) { application.settings }
  let(:root) { Dir.pwd }

  before { allow(settings).to receive(:environment).and_return('production') }
  before { allow(settings).to receive(:root).and_return(root) }

  let(:config) { Pathname(root).join('config') }

  it_behaves_like 'framework integration'
end
