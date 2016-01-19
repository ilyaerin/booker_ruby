require 'spec_helper'

describe Booker::Client do
  let(:client) { Booker::Client.new(base_url: 'http://foo', temp_access_token: 'token', temp_access_token_expires_at: Time.now + 1.minute) }

  describe '.new' do
    it 'builds a client with the valid options given' do
      expect(client.base_url).to eq 'http://foo'
      expect(client.temp_access_token).to eq 'token'
      expect(client.temp_access_token_expires_at).to be_a(Time)
    end
  end

  describe '#get' do
    let(:http_party_options) {
      {
          headers: {"Content-Type"=>"application/json; charset=utf-8"},
          query: data,
          timeout: 120
      }
    }
    let(:data) { {data: 'datum'} }
    let(:resp) { {'Results' => [data]} }

    it 'makes the request using the options given' do
      expect(client).to receive(:get_booker_resources).with(:get, '/blah/blah', data, nil, Booker::Models::Model).and_call_original
      expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(Booker::Models::Model).to receive(:from_list).with([data]).and_return(['results'])
      expect(client.get('/blah/blah', data, Booker::Models::Model)).to eq ['results']
    end

    it 'allows you to not pass in a booker model' do
      expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(client.get('/blah/blah', data)).to eq [data]
    end
  end

  describe '#post' do
    let(:http_party_options) {
      {
          headers: {"Content-Type"=>"application/json; charset=utf-8"},
          body: post_data.to_json,
          timeout: 120
      }
    }
    let(:data) { {data: 'datum'} }
    let(:resp) { {'Results' => [data]} }
    let(:post_data) { {"lUserID" => 13240029,"lBusinessID" => "25142"} }

    it 'makes the request using the options given' do
      expect(client).to receive(:get_booker_resources).with(:post, '/blah/blah', nil, post_data.to_json, Booker::Models::Model).and_call_original
      expect(HTTParty).to receive(:post).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(Booker::Models::Model).to receive(:from_list).with([data]).and_return(['results'])
      expect(client.post('/blah/blah', post_data, Booker::Models::Model)).to eq ['results']
    end

    it 'allows you to not pass in a booker model' do
      expect(HTTParty).to receive(:post).with("#{client.base_url}blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(client.post('blah/blah', post_data)).to eq [data]
    end
  end

  describe '#put' do
    let(:http_party_options) {
      {
        headers: {"Content-Type"=>"application/json; charset=utf-8"},
        body: post_data.to_json,
        timeout: 120
      }
    }
    let(:data) { {data: 'datum'} }
    let(:resp) { {'Results' => [data]} }
    let(:post_data) { {"lUserID" => 13240029,"lBusinessID" => "25142"} }

    it 'makes the request using the options given' do
      expect(client).to receive(:get_booker_resources).with(:put, '/blah/blah', nil, post_data.to_json, Booker::Models::Model).and_call_original
      expect(HTTParty).to receive(:put).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(Booker::Models::Model).to receive(:from_list).with([data]).and_return(['results'])
      expect(client.put('/blah/blah', post_data, Booker::Models::Model)).to eq ['results']
    end

    it 'allows you to not pass in a booker model' do
      expect(HTTParty).to receive(:put).with("#{client.base_url}blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(client.put('blah/blah', post_data)).to eq [data]
    end
  end

  describe '#paginated_request' do
    let(:path) { '/appointments' }

    context 'valid params' do
      let(:params_1) do
        {
            'UsePaging' => true,
            'PageSize' => 3,
            'PageNumber' => 1
        }
      end
      let(:results) { [result_1, result_2, result_3] }
      let(:result_1) { Booker::Models::Customer.new(LocationID: 123, FirstName: 'Jim') }
      let(:result_2) { Booker::Models::Customer.new(LocationID: 456) }
      let(:result_3) { Booker::Models::Customer.new(LocationID: 123, FirstName: 'Jim') }
      let(:base_paginated_request_args) { {method: 'method', path: path, params: params_1, model: Booker::Models::Model} }
      let(:paginated_request_args) { base_paginated_request_args }

      before { expect(client).to receive(:send).with('method', path, params_1, Booker::Models::Model).and_return(results) }

      context 'fetch all is true' do
        let(:params_2) { params_1.merge('PageNumber' => (params_1['PageNumber'] + 1)) }
        let(:params_3) { params_1.merge('PageNumber' => (params_1['PageNumber'] + 2)) }
        let(:result_4) { Booker::Models::Customer.new(LocationID: 123, FirstName: 'Jim') }
        let(:result_5) { Booker::Models::Customer.new(LocationID: 123, FirstName: 'John') }
        let(:total_missing) { params_2['PageSize'] - results2.length }
        let(:raven_msg) { "Page of #{path} has less records then specified in page size. Ensure this is not last page of request" }
        let(:results2) { [result_4, result_5] }
        let(:results3) { [] }

        before do
          expect(client).to receive(:send).with('method', path, params_2, Booker::Models::Model).and_return(results2)
          expect(client).to receive(:send).with('method', path, params_3, Booker::Models::Model).and_return(results3)
          expect(client).to_not receive(:log_issue)
        end

        it 'calls the request method for each page, returning the combined result set' do
          expect(client.paginated_request(paginated_request_args)).to eq [result_1, result_2, result_3, result_4, result_5]
        end
      end

      context 'fetch all is false' do
        let(:paginated_request_args) { base_paginated_request_args.merge(fetch_all: false) }

        it 'returns the first page of results' do
          expect(client.paginated_request(paginated_request_args)).to eq results
        end
      end
    end

    context 'invalid params' do
      let(:use_paging) { true }
      let(:page_size) { 2 }
      let(:page_number) { 1 }

      it 'invalid UsePaging' do
        [nil, false].each do |val|
          expect{client.paginated_request(method: 'method', path: path, params: {
              'UsePaging' => val,
              'PageSize' => page_size,
              'PageNumber' => page_number
            }, model: Booker::Models::Model)}.to raise_error(ArgumentError, 'params must include valid PageSize, PageNumber and UsePaging')
        end
      end

      it 'invalid PageSize' do
        [nil, 0].each do |val|
          expect{client.paginated_request(method: 'method', path: path, params: {
              'UsePaging' => use_paging,
              'PageSize' => val,
              'PageNumber' => page_number
            }, model: Booker::Models::Model)}.to raise_error(ArgumentError, 'params must include valid PageSize, PageNumber and UsePaging')
        end
      end

      it 'invalid PageNumber' do
        [nil, 0].each do |val|
          expect{client.paginated_request(method: 'method', path: path, params: {
              'UsePaging' => use_paging,
              'PageSize' => page_size,
              'PageNumber' => val
            }, model: Booker::Models::Model)}.to raise_error(ArgumentError, 'params must include valid PageSize, PageNumber and UsePaging')
        end
      end
    end

    context 'result is not a list' do
      let(:params) {{
        'UsePaging' => true,
        'PageSize' => 2,
        'PageNumber' => 1
      }}

      before do
        expect(client).to receive(:send).with('method', path, params, Booker::Models::Model).and_return('foo')
      end

      it 'raises error' do
        expect{client.paginated_request(method: 'method', path: path, params: params, model: Booker::Models::Model)}.to raise_error(StandardError, "Result from paginated request to #{path} with params: {\"UsePaging\"=>true, \"PageSize\"=>2, \"PageNumber\"=>1} is not a collection")
      end
    end
  end

  describe '#get_booker_resources' do
    let(:data) { {data: 'datum'} }
    let(:resp) { {'Results' => [data]} }
    let(:params) { {foo: 'bar'} }
    let(:body) { {bar: 'foo'} }
    let(:http_party_options) {
      {
        headers: {"Content-Type"=>"application/json; charset=utf-8"},
        body: body,
        query: params,
        timeout: 120
      }
    }

    before { allow_message_expectations_on_nil }

    it 'returns the results if they are present' do
      expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
      expect(resp).to receive(:success?).and_return(true)
      expect(client.get_booker_resources(:get, '/blah/blah', params, body)).to eq [data]
    end

    context 'model passed in and no Results' do
      let(:resp) { {'Treatments' => [data]} }

      it 'returns the services if they are present and results is not' do
        expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
        expect(resp).to receive(:success?).and_return(true)
        expect(client.get_booker_resources(:get, '/blah/blah', params, body, Booker::Models::Treatment)).to eq [data]
      end

      context 'singular response' do
        let(:resp) { {'Treatment' => data } }

        it 'returns the data' do
          expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
          expect(resp).to receive(:success?).and_return(true)
          expect(client.get_booker_resources(:get, '/blah/blah', params, body, Booker::Models::Treatment)).to eq data
        end
      end
    end

    context 'no Results' do
      let(:resp) { {'Foo' => []} }

      it 'returns the full resp' do
        expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
        expect(resp).to receive(:success?).and_return(true)
        expect(client.get_booker_resources(:get, '/blah/blah', params, body)).to eq resp
      end
    end

    context 'response not present on first request' do
      let(:resp) { nil }
      let(:resp2) { {'Results' => [data]} }

      it 'makes another request, returns results' do
        expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
        expect(resp).to receive(:success?).and_return(true)
        expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp2)
        expect(resp2).to receive(:success?).and_return(true)
        expect(client.get_booker_resources(:get, '/blah/blah', params, body)).to eq [data]
      end

      context 'no Results' do
        let(:resp2) { {'foo' => []} }

        it 'returns the full resp' do
          expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp)
          expect(resp).to receive(:success?).and_return(true)
          expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", http_party_options).and_return(resp2)
          expect(resp2).to receive(:success?).and_return(true)
          expect(client.get_booker_resources(:get, '/blah/blah', params, body)).to eq resp2
        end
      end

      context 'no response on second request' do
        let(:resp2) { nil }

        it 'raises Booker::Error' do
          expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", kind_of(Hash)).and_return(resp)
          expect(resp).to receive(:success?).and_return(true)
          expect(HTTParty).to receive(:get).with("#{client.base_url}/blah/blah", kind_of(Hash)).and_return(resp2)
          expect(resp2).to receive(:success?).and_return(true)
          expect{client.get_booker_resources(:get, '/blah/blah', params, body)}.to raise_error(Booker::Error)
        end
      end
    end
  end

  describe '#access_token' do
    let(:original_token) { 'token' }

    context 'booker_temp_access_token present and not expired' do
      before do
        client.temp_access_token = original_token
        client.temp_access_token_expires_at = (Time.zone.now + 1.minute)
      end

      it 'returns the booker_temp_access_token' do
        expect(client.access_token).to eq original_token
      end
    end

    context 'booker_temp_access_token present, but is expired' do
      before do
        client.temp_access_token = original_token
        client.temp_access_token_expires_at = (Time.zone.now - 1.minute)
      end

      it 'returns the updated booker_temp_access_token' do
        expect(client).to receive(:get_access_token).and_return('new token')
        expect(client.access_token).to eq 'new token'
      end
    end

    context 'booker_temp_access_token nil and is not expired' do
      before do
        client.temp_access_token = nil
        client.temp_access_token_expires_at = (Time.zone.now + 1.minute)
      end

      it 'returns the updated booker_temp_access_token' do
        expect(client).to receive(:get_access_token).and_return('new token')
        expect(client.access_token).to eq 'new token'
      end
    end
  end

  describe '#handle_errors!' do
    let(:resp) { {} }

    context 'booker error present' do
      before { expect(resp).to_not receive(:handle_errors) }

      context 'invalid_client' do
        let(:resp) { {'error' => 'invalid_client'} }

        it 'raises Booker::Error' do
          expect{client.handle_errors!('foo', resp)}.to raise_error(Booker::InvalidApiCredentials)
        end
      end

      context 'invalid access token' do
        let(:resp) { {'error' => 'invalid access token'} }

        context 'get_access_token_data raises error' do
          before { expect(client).to receive(:get_access_token).and_raise(StandardError) }

          it 'raises' do
            expect{client.handle_errors!('foo', resp)}.to raise_error(StandardError)
          end
        end

        context 'update_access_token_data does not raise error' do
          before { expect(client).to receive(:get_access_token).and_return true }

          it 'sets credentials verified to true and returns nil' do
            expect(client.handle_errors!('foo', resp)).to be nil
          end
        end
      end

      context 'no error match' do
        let(:resp) { {'error' => 'blah error'} }

        it 'raises Booker::Error' do
          expect(Booker::Error).to receive(:new).with('foo', resp).and_call_original
          expect{client.handle_errors!('foo', resp)}.to raise_error(Booker::Error)
        end
      end
    end

    context 'response unsuccessful' do
      before { expect(resp).to receive(:success?).and_return(false) }

      it 'raises Booker::Error' do
        expect(Booker::Error).to receive(:new).with('foo', resp).and_call_original
        expect{client.handle_errors!('foo', resp)}.to raise_error(Booker::Error)
      end
    end

    context 'successful response' do
      before { expect(resp).to receive(:success?).and_return(true) }

      it 'returns the resp' do
        expect(client.handle_errors!('foo', resp))
      end
    end
  end

  describe '#log_issue' do
    let(:message) { 'message' }
    let(:extra_info) { 'extra' }

    after { client.log_issue(message, extra_info) }

    it 'calls the log message block' do
      expect(Booker.config[:log_message]).to receive(:call).with(message, extra_info)
    end

    context 'log message block not set' do
      it 'does not call the block' do
        expect(Booker).to receive(:config).and_return({})
        expect_any_instance_of(Proc).to_not receive(:call)
      end
    end
  end
end