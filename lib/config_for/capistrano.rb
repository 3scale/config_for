require 'rake/tasklib'
require 'pathname'
require 'tempfile'
require 'capistrano/dsl'
require 'active_support/core_ext/hash/keys'
require 'yaml'

module ConfigFor
  module Capistrano

    # inspired by https://github.com/rspec/rspec-core/blob/6b7f55e4fb36226cf830983aab8da8308f641708/lib/rspec/core/rake_task.rb

    # Rake Task generator for generating and uploading config files through Capistrano.
    # @example generating task for database.yml
    #   ConfigFor::Capistrano::Task.new(:database)
    # @example changing the folder
    #   ConfigFor::Capistrano::Task.new(:database) { |task| task.folder = 'configuration' }
    class Task < ::Rake::TaskLib
      include ::Capistrano::DSL


      # @!attribute name
      #   @return [String] the name of the task and subtasks namespace
      attr_accessor :name

      # @!attribute folder
      #   @return [String] folder to upload the generated config
      attr_accessor :folder

      # @!attribute tempfile
      #   @return [Tempfile] temporary file for generating the config before upload
      attr_accessor :tempfile

      # Generates new tasks with for uploading #name
      # @param [String, Symbol] name name of this tasks and subtasks
      # @param &block gets evaluated before defining the tasks
      # @yieldparam [Task] task the task itself so you can modify it before it gets defined
      def initialize(name, &block)
        @name = name
        @folder = 'config'
        @file = "#{name}.yml"
        @roles = :all
        @tempfile = ::Tempfile.new(@file)
        @variable = "#{name}_yml".to_sym

        yield(self) if block_given?

        desc "Generate #{name} uploader" unless ::Rake.application.last_comment
        define
      end


      # Path where will be the file uploaded
      # Is a join of #folder and #file
      def path
        ::File.join(@folder, @file)
      end

      # Invokes the task to do the upload
      def run_task
        invoke("#{name}:upload")
      end

      # Generated YAML content
      # Gets the configuration from #variable, deep stringifies keys and returns YAML
      # @return [String] serialized YAML
      def yaml
        config = fetch(@variable, {})
        config.deep_stringify_keys.to_yaml
      end

      private

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

          task :generate do
            @tempfile.write(yaml)
            @tempfile.close(false)
          end
        end

        remote_file path => @tempfile.path, roles: @roles
        file @tempfile.path => "#{name}:generate"

        desc "Generate #{path}"
        task(name, &method(:run_task))

        before 'deploy:check:linked_files', @name
      end


      private

      # This reimplements Capistrano::DSL::TaskEnhancements#remote_file
      # but uses UploadTask instead of Rake::Task

      # TODO: can be removed when https://github.com/capistrano/capistrano/pull/1144
      # is merged and released

      def remote_file(task)
        target_roles = task.delete(:roles)

        UploadTask.define_task(task) do |t|
          prerequisite_file = t.prerequisites.first
          file = shared_path.join(t.name)

          on roles(target_roles) do
            unless test "[ -f #{file} ]"
              info "Uploading #{prerequisite_file} to #{file}"
              upload! File.open(prerequisite_file), file
            end
          end

        end
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
  end
end
