module Cucumber
  module Chef

    class TestRunnerError < Error; end

    class TestRunner

################################################################################

      def initialize(project_dir, stdout=STDOUT, stderr=STDERR, stdin=STDIN)
        @project_dir = project_dir
        @stdout, @stderr, @stdin = stdout, stderr, stdin
        @stdout.sync = true if @stdout.respond_to?(:sync=)

        @test_lab = Cucumber::Chef::TestLab.new(@stdout, @stderr, @stdin)

        @ssh = Cucumber::Chef::SSH.new(@stdout, @stderr, @stdin)
        @ssh.config[:host] = @test_lab.labs_running.first.public_ip_address
        @ssh.config[:ssh_user] = "ubuntu"
        @ssh.config[:identity_file] = Cucumber::Chef::Config[:aws][:identity_file]

        @stdout.puts("Cucumber-Chef Test Runner Initalized!")
      end

################################################################################

      def run(*args)
        reset_project
        upload_project

        @stdout.puts("Executing Cucumber-Chef Test Runner")
        remote_path = File.join("/", "home", "ubuntu", "cucumber-chef", File.basename(@project_dir), "features")
        cucumber_options = args.flatten.compact.uniq.join(" ")
        command = [ "sudo cucumber", cucumber_options, remote_path ].flatten.compact.join(" ")

        @ssh.exec(command)
      end


################################################################################
    private
################################################################################

      def reset_project
        @stdout.print("Cleaning up any previous test runs...")
        Cucumber::Chef.spinner do
          remote_path = File.join("/", "home", "ubuntu", "cucumber-chef")

          command = "rm -rf #{remote_path}"
          @ssh.exec(command)

          command = "mkdir -p #{remote_path}"
          @ssh.exec(command)
        end
        @stdout.print("done.\n")
      end

################################################################################

      def upload_project
        @stdout.print("Uploading files required for this test run...")
        Cucumber::Chef.spinner do
          config_path = Cucumber::Chef.locate(:directory, ".cucumber-chef")
          cucumber_config_file = File.expand_path(File.join(config_path, "cucumber.yml"))
          if File.exists?(cucumber_config_file)
            remote_file = File.join("/", "home", "ubuntu", File.basename(cucumber_config_file))
            @ssh.upload(cucumber_config_file, remote_file)
          end

          local_path = @project_dir
          remote_path = File.join("/", "home", "ubuntu", "cucumber-chef", File.basename(@project_dir))
          @ssh.upload(local_path, remote_path)
        end
        @stdout.print("done.\n")
      end

################################################################################

    end

  end
end
