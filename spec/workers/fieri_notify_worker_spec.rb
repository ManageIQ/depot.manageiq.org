require 'spec_helper'
require 'webmock/rspec'

describe FieriNotifyWorker, pending: "no fieri" do
  let(:extension) { create(:extension) }

  it 'sends a POST request to the configured fieri_url for extension evaluation' do
    stub_request(:any, ENV['FIERI_URL'])

    worker = FieriNotifyWorker.new
    result = worker.perform(extension.extension_versions.first.id)

    expect(result.class).to eql(Net::HTTPOK)
  end
end
