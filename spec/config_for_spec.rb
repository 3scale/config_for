require 'config_for'

RSpec.describe ConfigFor do
  let(:env) { 'production' }
  subject(:config) { config_for(self.class.description) }

  def config_for(name)
    described_class.load_config(fixtures_path, name, env)
  end

  context 'database' do
    it { is_expected.to eq('host' => 'localhost', 'port' => 3306) }
    it { is_expected.to include(port: 3306, host: 'localhost') }
  end

  context 'unknown' do
    it do
      expect{ subject }
          .to raise_error(RuntimeError,
                          'Could not load configuration. Can\'t read spec/fixtures/unknown.yml')
    end
  end
end
