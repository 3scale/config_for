require 'rake/tasklib'
require 'pathname'
require 'tempfile'
require 'capistrano/dsl'
require 'active_support/core_ext/hash/keys'

module ConfigFor
  module Capistrano

    # inspired by https://github.com/rspec/rspec-core/blob/6b7f55e4fb36226cf830983aab8da8308f641708/lib/rspec/core/rake_task.rb

    class Task < ::Rake::TaskLib
      include ::Capistrano::DSL

      attr_reader :name

      attr_accessor :folder

      attr_reader :tempfile

      def initialize(name, *args, &task_block)
        @name = name
        @folder = 'config'
        @file = "#{name}.yml"
        @roles = :all
        @tempfile = ::Tempfile.new(@file)
        @variable = "#{name}_yml".to_sym

        desc "Generate #{name} uploader" unless ::Rake.application.last_comment
        define(args, &task_block)
      end


      def path
        ::File.join(@folder, @file)
      end

      def run_task
        invoke("#{name}:upload")
      end

      def yaml
        config = fetch(@variable, {})
        config.deep_stringify_keys.to_yaml
      end

      private

      def define(args, &task_block)
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

        desc 'upload remote file'
        remote_file path => @tempfile.path, roles: @roles
        desc 'generate local file'
        file @tempfile.path => "#{name}:generate"

        desc "Generate #{path}"
        task(name, *args) do |_, task_args|
          task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
          run_task
        end

        before 'deploy:check:linked_files', @name
      end
    end
  end
end
