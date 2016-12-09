require 'rake/tasklib'
require 'pathname'
require 'tempfile'
require 'sshkit'
require 'capistrano/dsl'
require 'active_support/core_ext/hash/keys'
require 'yaml'

module ConfigFor
  module Capistrano

    class UploadFileTask < ::Rake::TaskLib

      attr_reader :path, :tempfile

      attr_accessor :generator
      # Rake Task generator for uploading files through Capistrano
      #
      # @example generating task for config/unicorn.rb
      #   ConfigFor::Capistrano::UploadFileTask.new('config/unicorn.rb', roles: :web) do |file|
      #     file.write('some template')
      #   end
      #
      #   Rake::Task['config/unicorn.rb'].invoke # uploads that file if it does not exist
      # @param [Pathname, String] path the path of the file to be uploaded
      # @param [Hash] options the options
      # @option options [Array<Symbol>,Symbol] :roles (:all) the roles of servers to apply to
      # @option options [true,false] :override (false) upload file on every run
      # @yieldparam [Tempfile] file yields the tempfile so you generate the file to be uploaded
      def initialize(path, options = {}, &block)
        @path = path
        @roles = options.fetch(:roles, :all)
        @override = options.fetch(:override, false)
        @tempfile = ::Tempfile.new(File.basename(@path))
        @generator = block || ->(_file){ puts 'Did not passed file generator' }

        define
      end

      private

      include ::Capistrano::DSL

      def define
        desc "Upload file to #{path}"
        remote_file(path => @tempfile.path, roles: @roles, override: @override)
        desc "Generate file #{@path} to temporary location"

        generate_file(@tempfile.path, &method(:generate))
      end

      def generate(*)
        @generator.call(@tempfile)
        @tempfile.close(false)
      end

      # So it is always generated, because it is always needed
      def generate_file(task, &block)
        GenerateFileTask.define_task(task, &block)
      end

      # This reimplements Capistrano::DSL::TaskEnhancements#remote_file
      # but uses UploadTask instead of Rake::Task

      # TODO: can be removed when https://github.com/capistrano/capistrano/pull/1144
      # is merged and released

      def remote_file(task)
        target_roles = task.delete(:roles)

        UploadTask.define_task(task) do |t|
          prerequisite_file = t.prerequisites.first
          file = shared_path.join(t.name).to_s.shellescape

          on roles(target_roles) do
            if task.delete(:override) || !test("[ -f #{file} ]")
              info "Uploading #{prerequisite_file} to #{file}"
              upload! File.open(prerequisite_file), file
            end
          end

        end
      end
    end

    # inspired by https://github.com/rspec/rspec-core/blob/6b7f55e4fb36226cf830983aab8da8308f641708/lib/rspec/core/rake_task.rb

    # Rake Task generator for generating and uploading config files through Capistrano.
    # @example generating task for database.yml
    #   ConfigFor::Capistrano::Task.new(:database)
    # @example changing the folder
    #   ConfigFor::Capistrano::Task.new(:database) { |task| task.folder = 'configuration' }
    class Task < ::Rake::TaskLib
      # @!attribute config
      #   @return [ConfigFor::Capistrano::UploadFileTask] the task used to generate the config
      attr_reader :config

      # @!attribute name
      #   @return [String] the name of the task and subtasks namespace
      attr_accessor :name

      # @!attribute folder
      #   @return [String] folder to upload the generated config
      attr_accessor :folder

      # Generates new tasks with for uploading #name
      # @param [String, Symbol] name name of this tasks and subtasks
      # @param &block gets evaluated before defining the tasks
      # @option options [true,false] :override (false) upload file on every run
      # @yieldparam [Task] task the task itself so you can modify it before it gets defined
      def initialize(name, options = {}, &block)
        @name = name
        @folder = 'config'
        @file = "#{name}.yml"
        @variable = "#{name}_yml".to_sym
        @roles = options.fetch(:roles, :all)
        @override = options.fetch(:override, false)

        yield(self) if block_given?

        @config = ConfigFor::Capistrano::UploadFileTask.new(path, roles: @roles, override: @override, &method(:generate))

        desc "Generate #{name} uploader" unless ::Rake.application.last_description
        define
      end


      # Is a join of #folder and #file
      def path
        ::File.join(@folder, @file)
      end

      # Invokes the task to do the upload
      def run_task(_task, _args)
        invoke("#{name}:upload")
      end

      # Generated YAML content
      # Gets the configuration from #variable, deep stringifies keys and returns YAML
      # @return [String] serialized YAML
      def yaml
        config = fetch(@variable, {})
        stringified = if config.respond_to?(:deep_stringify_keys)
                        config.deep_stringify_keys
                      else
                        # TODO: remove when dropping rails 3 support
                        # two level stringify for rails 3 compatibility
                        config.stringify_keys.each_value(&:stringify_keys!)
                      end
        stringified.to_yaml
      end

      private

      include ::Capistrano::DSL

      def generate(file)
        file.write(yaml)
      end

      def define
        namespace name do
          desc "Upload #{path} to remote servers"
          task upload: path

          desc "Remove #{path} from current and shared path"
          task :remove do
            files = []
            files << shared_path.join(path)
            files << current_path.join(path)

            files.each do |file|
              escaped = file.to_s.shellescape

              on roles(@roles) do
                if test "[ -e #{escaped} ]"
                  execute :rm, escaped
                end
              end
            end
          end

          desc "Reset #{name} config"
          task reset: [:remove, :upload]
        end

        before 'deploy:check:linked_files', @name

        desc "Generate #{path}"
        task(name, &method(:run_task))
      end
    end

    private

    # Inheriting from Rake::FileCreationTask because it does not scope
    # task by namespace. Capistrano uses default Rake::Task which inside namespace produces:
    # namespace:path/file.ext instead of just path/file.ext

    class UploadTask < Rake::FileCreationTask
      def needed?
        true
      end
    end

    class GenerateFileTask < Rake::FileTask
      def needed?
        true
      end
    end
  end
end
