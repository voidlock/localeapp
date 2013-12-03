require 'spec_helper'
require 'localeapp/cli/update'

describe Localeapp::CLI::Update, "#execute" do
  before do
    @output = StringIO.new
    @updater = Localeapp::CLI::Update.new(:output => @output)
  end

  it "uses configured poller" do
    with_configuration do
      Localeapp::Poller.should_not_receive(:new)
      Localeapp.poller.should_receive(:poll!)
      @updater.execute
    end
  end
end
