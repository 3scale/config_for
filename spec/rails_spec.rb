require 'rails'
require 'rails/application'
require 'config_for'
require 'config_for/rails'

RSpec.describe ConfigFor::Rails do
  subject(:railtie) { Class.new(Rails::Application) }
  it { expect(subject.ancestors).to include(described_class) }

  context 'application' do
    before { allow(Rails).to receive(:env).and_return('production') }

    subject(:application) { railtie.instance }

    around(:each) { |ex| railtie.configure(&ex) }
    around(:each) { |ex| MemFs.activate(&ex) }

    context 'database' do
      let(:config_file) { Rails.root.join('config/database.yml') }
      let!(:config) { fixtures_path.join('database.yml').read }

      subject{ application.config_for(:database) }

      before do
        MemFs.touch(config_file)
        File.open(config_file.to_s, 'w'){|io| io.puts(config) }
      end

      it { is_expected.to include(host: 'localhost') }
    end
  end
end
