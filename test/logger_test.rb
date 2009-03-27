require File.dirname(__FILE__) + '/helper'

class LoggerTest < ActiveSupport::TestCase
  def stub_http(response)
    @http = stub(:post => response,
                 :read_timeout= => nil,
                 :open_timeout= => nil,
                 :use_ssl= => nil)
    Net::HTTP.stubs(:new).returns(@http)
  end

  context "loggers are stubbed out" do
    setup do
      HoptoadNotifier.stubs(:logger)
      HoptoadNotifier.logger.stubs(:info)
      STDERR.stubs(:puts)
    end

    context "state is kept" do
      setup do
        @verbose = HoptoadNotifier.verbose
      end

      context "verbose logging is on" do
        before_should "report that notifier is ready" do
          HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Notifier (.*) ready/ }
        end

        setup do
          HoptoadNotifier.configure { |c| c.verbose = true }
        end

        context "controller is hooked up to the notifier" do
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
            HoptoadNotifier.stubs(:environment_info)
          end

          context "expection is raised and notification is successful" do
            before_should "send environment info" do
              HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
            end

            setup do
              stub_http(Net::HTTPSuccess)
              request("do_raise")
            end
          end

          context "expection is raised and notification fails" do
            before_should "send environment info" do
              HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
            end

            setup do
              stub_http(Net::HTTPSuccess)
              request("do_raise")
            end
          end
        end
      end

      context "verbose logging is off" do
        before_should "not report that notifier is ready" do
          HoptoadNotifier.expects(:write_verbose_log).never
        end

        setup do
          HoptoadNotifier.configure { |c| c.verbose = false }
        end
      end

      teardown do
        HoptoadNotifier.verbose = @verbose
      end
    end
  end
end
