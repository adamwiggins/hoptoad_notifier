require File.dirname(__FILE__) + '/helper'

class LoggerTest < ActiveSupport::TestCase
  def configure_verbose
    HoptoadNotifier.configure do |config|
      config.verbose = true
    end
  end

  def configure_normal
    HoptoadNotifier.configure {}
  end

  context "verbose logging" do
    setup do
      HoptoadNotifier.stubs(:logger)
      HoptoadNotifier.logger.stubs(:info)
      STDERR.stubs(:puts)
    end

    should "report that it is enabled" do
      HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Notifier (.*) ready/ }
      configure_verbose
    end

    should "not report if option is off" do
      HoptoadNotifier.expects(:write_verbose_log).never
      configure_normal
    end

    context "when exceptions are thrown" do
      setup do
        class ::LoggerController < ::ActionController::Base
          include HoptoadNotifier::Catcher
          include TestMethods

          def rescue_action e
            rescue_action_in_public e
          end
        end
        ::ActionController::Base.logger = Logger.new(StringIO.new)
        @controller = ::LoggerController.new
        @controller.stubs(:public_environment?).returns(true)
        @controller.stubs(:rescue_action_in_public_without_hoptoad)
        @controller.stubs(:environment_info)

        @http = stub(:post => Net::HTTPSuccess, :read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
        Net::HTTP.stubs(:new).returns(@http)
        HoptoadNotifier.port = nil
        HoptoadNotifier.host = nil
        HoptoadNotifier.proxy_host = nil
      end

      should "report environment info if option is on" do
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Notifier (.*) ready/ }
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
        configure_verbose

        assert_nothing_raised do
          request("do_raise")
        end
      end

      should "not report environment info if option is on" do
        @controller.expects(:write_verbose_log).never
        configure_normal

        assert_nothing_raised do
          request("do_raise")
        end
      end
    end
  end
end
