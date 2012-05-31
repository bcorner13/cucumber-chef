module Cucumber
  module Chef

    class ProvisionerError < Error; end

    class Provisioner
      attr_accessor :stdout, :stderr, :stdin

      def initialize(server, stdout=STDOUT, stderr=STDERR, stdin=STDIN)
        @server = server
        @stdout, @stderr, @stdin = stdout, stderr, stdin
        @stdout.sync = true if @stdout.respond_to?(:sync=)

        @command = Cucumber::Chef::Command.new(@stdout, @stderr, @stdin)
        @user = ENV['OPSCODE_USER'] || ENV['USER']
        @cookbooks_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "chef_repo", "cookbooks"))
        @roles_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "chef_repo", "roles"))
      end

      def build
        template_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "cucumber", "chef", "templates", "bootstrap", "ubuntu-chef-server.erb"))

        bootstrap(template_file)
        download_credentials
        render_knife_rb

        upload_cookbook
        upload_role
        tag_node
        add_node_role
      end


    private

      def bootstrap(template_file)
        raise ProvisionerError, "You must have the environment variable 'USER' set." if !@user

        bootstrap = Cucumber::Chef::Bootstrap.new(@stdout, @stderr, @stdin)
        bootstrap.config[:host] = @server.public_ip_address
        bootstrap.config[:ssh_user] = "ubuntu"
        bootstrap.config[:use_sudo] = true
        bootstrap.config[:identity_file] = Cucumber::Chef::Config[:aws][:identity_file]
        bootstrap.config[:template_file] = template_file
        bootstrap.config[:context][:hostname] = "cucumber-chef-test-lab"
        bootstrap.config[:context][:chef_server] = @server.public_ip_address
        bootstrap.config[:context][:amqp_password] = "p@ssw0rd1"
        bootstrap.config[:context][:admin_password] = "p@ssw0rd1"
        bootstrap.config[:context][:user] = @user
        bootstrap.run
      end

      def download_credentials
        ssh = Cucumber::Chef::SSH.new(@stdout, @stderr, @stdin)
        ssh.config[:host] = @server.public_ip_address
        ssh.config[:ssh_user] = "ubuntu"
        ssh.config[:identity_file] = Cucumber::Chef::Config[:aws][:identity_file]
        local_path = File.expand_path(File.join(Dir.pwd, ".cucumber-chef"))
        remote_path = File.join("/", "home", ssh.config[:ssh_user], ".chef")

        FileUtils.mkdir_p(local_path)

        files = [ "#{@user}.pem", "validation.pem" ]
        files.each do |file|
          ssh.download(File.join(remote_path, file), File.join(local_path, file))
        end
      end

      def render_knife_rb
        template_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "cucumber", "chef", "templates", "chef", "knife-rb.erb"))
        knife_rb = File.expand_path(File.join(Dir.pwd, ".cucumber-chef", "knife.rb"))

        context = { :chef_server => @server.public_ip_address }
        File.open(knife_rb, 'w') do |f|
          f.puts(Cucumber::Chef::Template.render(template_file, context))
        end
      end

      def upload_cookbook
        @command.knife("cookbook upload cucumber-chef", "-o", @cookbooks_path)
      end

      def upload_role
        @command.knife("role from file", File.join(@roles_path, "test_lab.rb"))
      end

      def tag_node
        @command.knife("tag create cucumber-chef-test-lab", Cucumber::Chef::Config[:mode])
      end

      def add_node_role
        @command.knife("node run_list add", "cucumber-chef-test-lab", "\"role[test_lab]\"")
      end

    end

  end
end
