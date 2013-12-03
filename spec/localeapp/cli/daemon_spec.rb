require 'spec_helper'

describe Localeapp::CLI::Daemon do
  let(:config) { {daemon_log_file: 'tmp/test_log.log', daemon_pid_file: 'tmp/test_pid.pid'} }
  let(:command) { Localeapp::CLI::Daemon.new }
  let(:poller) { Localeapp::Poller.new }

  context "#execute(options)" do
    let(:interval) { 5 }

    before do
      command.stub(:update_loop)
    end

    before do
      [config[:daemon_log_file], config[:daemon_pid_file]].each do |file|
        File.delete(file) if File.exists?(file)
      end

      config.each do |setting, value|
        Localeapp.configuration.send("#{setting}=", value)
      end
    end

    it "exits when interval isn't greater than 0" do
      command.should_receive(:exit_now!)
      command.execute(:interval => -1)
    end

    it "runs the loop directly when not running in background" do
      command.should_receive(:update_loop).with(interval)
      command.execute(:interval => interval)
    end

    it "runs the loop in the background when background options set" do
      command.should_receive(:run_in_background).with(interval)
      command.execute(:interval => interval, :background => true)
    end
  end

  context "#do_update" do
    it "use configured poller" do
      poller.should_receive(:poll!)
      Localeapp.should_receive(:poller).and_return(poller)

      command.do_update
    end

    it "should not reset configuration" do
      defaults = Localeapp.configure
      poller.should_receive(:poll!)
      Localeapp.should_receive(:configure).once.and_return(defaults)
      Localeapp.stub!(:poller).and_return(poller)

      command.do_update
    end

    it "update the poller.updated_at time" do
      poller.should_receive(:poll!).and_return(true)

      Localeapp.stub!(:poller).and_return(poller)
      command.do_update
    end
  end
end
