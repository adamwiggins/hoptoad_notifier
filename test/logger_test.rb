require File.dirname(__FILE__) + '/helper'

class LoggerTest < ActiveSupport::TestCase
  context "verbose logging" do
    setup do
      HoptoadNotifier.stubs(:logger)
    end

    should "report that it is enabled" do
      HoptoadNotifier.logger.expects(:info).with { |message| message =~ /Hoptoad Notifier (.*) ready/ }
      HoptoadNotifier.configure do |config|
        config.verbose = true
      end
    end

    should "not report if option is off" do
      HoptoadNotifier.logger.expects(:info).never
      HoptoadNotifier.configure {}
    end
  end
end
