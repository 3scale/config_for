require 'config_for'

RSpec.describe ConfigFor do
  let(:env) { 'production' }
  subject(:config) { config_for(self.class.metadata.fetch(:name)) }

  def config_for(name)
    described_class.load_config(fixtures_path, name, env)
  end

  context 'config', name: 'database' do
    it { is_expected.to eq('host' => 'localhost', 'port' => 3306) }
    it { is_expected.to include(port: 3306, host: 'localhost') }

    context 'with symbol as env' do
      let(:env) { :production }

      it { is_expected.to_not be_empty }
    end

    context 'with unknown env' do
      let(:env) { 'unknown' }
      it { is_expected.to be_empty }
    end
  end

  context 'config', name: 'unknown' do
    it do
      expect{ subject }
          .to raise_error(Errno::ENOENT, /^No such file or directory/)
    end
  end

  context 'load_config!', name: 'database' do
    def config_for(name)
      described_class.load_config!(fixtures_path, name, env)
    end

    context 'unknown env' do
      let(:env) { 'unknown' }
      it { expect{subject}
               .to raise_error(ConfigFor::MissingEnvironment, /database\.yml contains just \["production", "development"\], not unknown/) }
    end
  end
end
