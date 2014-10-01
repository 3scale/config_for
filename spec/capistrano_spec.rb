require 'config_for/capistrano'

RSpec.describe ConfigFor::Capistrano do

end

RSpec.describe ConfigFor::Capistrano::Task do
  def invoke(task, *args)
    rake_task(task).invoke(*args)
  end

  def rake_task(task)
    Rake::Task[task]
  end

  before do
    Rake.application = Rake::Application.new
    Rake::Task.define_task('deploy:check:linked_files')
  end

  context 'database task' do
    let!(:database_task) { described_class.new(:database) }
    subject(:task) { database_task }

    it { expect(task.path).to eq('config/database.yml') }

    context 'with configuration' do
      before{ stub_const('Capistrano::Configuration', configuration) }
      let(:configuration) { double('configuration', env: env) }
      let(:env) { { database_yml:  database_configuration } }
      let(:database_configuration) { { production: { host: 'localhost' } } }

      it { expect(task.yaml).to eq("---\nproduction:\n  host: localhost\n") }
    end

    let(:prerequisites) { subject.prerequisites }

    context 'tempfile' do
      subject { rake_task(task.tempfile.path) }
      it { expect(prerequisites).to eq(['database:generate']) }
    end

    context 'remote_file' do
      subject { rake_task('config/database.yml') }
      it { expect(prerequisites).to eq([task.tempfile.path]) }
    end

    context 'upload' do
      subject { rake_task('database:upload') }
      it { expect(prerequisites).to eq(['config/database.yml']) }
    end

    context 'remove' do
      subject { rake_task('database:remove') }
      it { expect(prerequisites).to eq([]) }
    end

    context 'reset' do
      subject { rake_task('database:reset') }
      it { expect(prerequisites).to eq(%w[remove upload]) }
    end
  end
end
