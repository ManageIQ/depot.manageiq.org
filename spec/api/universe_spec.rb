require 'spec_helper'

describe 'GET /universe' do
  let(:redis) { create(:extension, name: 'redis') }
  let(:apt) { create(:extension, name: 'apt') }
  let(:narf) { create(:extension, name: 'narf') }

  before do
    redis_version1 = create(
      :extension_version,
      extension: redis,
      license: 'MIT',
      version: '1.2.0'
    )
    redis_version2 = create(
      :extension_version,
      extension: redis,
      license: 'MIT',
      version: '1.3.0'
    )
    apt_version = create(
      :extension_version,
      extension: apt,
      license: 'BSD',
      version: '1.1.0'
    )
    narf_version = create(
      :extension_version,
      extension: narf,
      license: 'GPL',
      version: '1.4.0'
    )
    create(:extension_dependency, extension_version: redis_version1, extension: apt, name: 'apt', version_constraint: '>= 1.0.0')
    create(:extension_dependency, extension_version: redis_version1, extension: narf, name: 'narf', version_constraint: '>= 1.1.0')
    create(:extension_dependency, extension_version: redis_version2, extension: apt, name: 'apt', version_constraint: '>= 1.0.0')
  end

  it 'returns a 200' do
    get '/universe', format: :json
    expect(response).to be_success
  end

  it 'returns http URLs by default' do
    get '/universe', format: :json

    expect(response).to be_success
    expect(json_body['redis']['1.2.0']['location_path']).to match(%r{http://.*/api/v1})
    expect(json_body['redis']['1.2.0']['download_url']).to match(%r{http://.*/api/v1/extensions/redis/versions/1.2.0/download})
  end

  it 'has an http specific cache key' do
    expect(Rails.cache).to receive(:fetch).with('http-universe')

    get '/universe', format: :json
  end

  it 'has an https specific cache key' do
    expect(Rails.cache).to receive(:fetch).with('https-universe')

    get '/universe', { format: :json }, 'HTTPS' => 'on'
  end

  it "returns https URLs when ENV['PROTOCOL']=https" do
    get '/universe', { format: :json }, 'HTTPS' => 'on'

    expect(response).to be_success
    expect(json_body['redis']['1.2.0']['location_path']).to match(%r{https://.*/api/v1})
    expect(json_body['redis']['1.2.0']['download_url']).to match(%r{https://.*/api/v1/extensions/redis/versions/1.2.0/download})
  end

  it 'lists out extensions, their versions, and dependencies' do
    get '/universe', format: :json
    body = json_body
    expect(body.keys).to include('redis', 'apt', 'narf')
    expect(body['redis'].keys).to include('1.2.0', '1.3.0')
    expect(body['redis']['1.2.0'].keys).to include('dependencies', 'location_type', 'location_path')
    expect(body['redis']['1.2.0']['dependencies']).to eql('apt' => '>= 1.0.0', 'narf' => '>= 1.1.0')
    expect(body['redis']['1.2.0']['location_type']).to eql('opscode')
    expect(body['redis']['1.2.0']['location_path']).to match(%r{/api/v1})
    expect(body['redis']['1.2.0']['download_url']).to match(%r{/api/v1/extensions/redis/versions/1.2.0/download})
    expect(body['redis']['1.3.0'].keys).to include('dependencies', 'location_type', 'location_path')
    expect(body['redis']['1.3.0']['dependencies']).to eql('apt' => '>= 1.0.0')
    expect(body['redis']['1.3.0']['location_type']).to eql('opscode')
    expect(body['redis']['1.3.0']['location_path']).to match(%r{/api/v1})
    expect(body['redis']['1.3.0']['download_url']).to match(%r{/api/v1/extensions/redis/versions/1.3.0/download})
    expect(body['apt']['1.1.0']['dependencies']).to eql({})
  end
end
