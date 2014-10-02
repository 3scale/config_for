require 'rails'
require 'rails/application'
require 'config_for'
require 'config_for/rails'

RSpec.describe ConfigFor::Rails do
  # TODO: remove when dropping rails 3 compatibility
  after { Rails.application = nil }

  subject(:railtie) { Class.new(Rails::Application) }
  it { expect(subject.ancestors).to include(described_class) }

  context 'application' do
    let(:config) { Rails.root.join('config') }

    subject(:application) { railtie.instance }

    before { allow(Rails).to receive(:env).and_return('production') }

    around(:each) { |ex| railtie.configure(&ex) }

    it_behaves_like 'framework integration'
  end
end
