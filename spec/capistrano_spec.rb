require 'config_for/capistrano'

module RspecSupport
  def rake_task(task)
    Rake::Task[task]
  end

  def invoke(task, *args)
    rake_task(task).invoke(*args)
  end

  def self.included(base)
    base.before do
      Rake.application = Rake::Application.new
    end
  end
end

RSpec.describe ConfigFor::Capistrano do

end

RSpec.describe ConfigFor::Capistrano::UploadFileTask do
  include RspecSupport

  let!(:task_name) { self.class.description }
  subject!(:task) { described_class.new(task_name) }

  context 'config/unicorn.rb' do
    context 'upload_task' do
      subject(:upload_task) { rake_task(task.path) }
      it { expect(upload_task.prerequisites).to eq([task.tempfile.path]) }
    end

    context 'file_task' do
      subject(:file_task) { rake_task(task.tempfile.path) }

      it { expect(file_task).to be }
      it { expect(file_task).to be_needed }
    end
  end
end

RSpec.describe ConfigFor::Capistrano::Task do
  include RspecSupport

  before do
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

    context 'remote_file' do
      subject { rake_task('config/database.yml') }
      it { is_expected.to be }
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

  context 'task' do
    it 'accepts block to change folder' do
      task = described_class.new(:test) { |t| t.folder = 'other' }
      expect(task.folder).to eq('other')
      expect(rake_task('other/test.yml')).to be
    end

    it 'accepts block to change name' do
      task = described_class.new(:test) { |t| t.name = 'other' }
      expect(task.name).to eq('other')
      expect(rake_task('other')).to be
    end

    it 'invokes upload' do
      task = described_class.new(:test)
      expect(rake_task('test:upload')).to receive(:invoke)

      invoke(task.name)
    end
  end

  context 'task in namespace' do
    let!(:database_task) do
      Rake.application.in_namespace('namespace') do
        described_class.new(:database)
      end
    end

    let(:prerequisites) { subject.prerequisites }
    subject { rake_task(self.class.description) }

    context 'namespace:database:upload' do
      it { is_expected.to be }
      it { expect(prerequisites).to eq(['config/database.yml'])}
    end

    context 'namespace:database' do
      it { is_expected.to be }
    end

    context 'config/database.yml' do
      it { is_expected.to be_a(ConfigFor::Capistrano::UploadTask) }
    end
  end
end
