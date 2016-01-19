module Booker
  class Client
    attr_accessor :base_url, :client_id, :client_secret, :temp_access_token, :temp_access_token_expires_at, :token_store, :token_store_callback_method

    TimeZone = 'Eastern Time (US & Canada)'.freeze

    def initialize(options = {})
      options.each do |key, value|
        send(:"#{key}=", value)
      end
    end

    def get(path, params, booker_model=nil)
      booker_resources = get_booker_resources(:get, path, params, nil, booker_model)

      build_resources(booker_resources, booker_model)
    end

    def post(path, data, booker_model=nil)
      booker_resources = get_booker_resources(:post, path, nil, data.to_json, booker_model)

      build_resources(booker_resources, booker_model)
    end

    def put(path, data, booker_model=nil)
      booker_resources = get_booker_resources(:put, path, nil, data.to_json, booker_model)

      build_resources(booker_resources, booker_model)
    end

    def paginated_request(method:, path:, params:, model: nil, fetched: [], fetch_all: true)
      page_size = params['PageSize']
      page_number = params['PageNumber']

      if page_size.nil? || page_size < 1 || page_number.nil? || page_number < 1 || !params['UsePaging']
        raise ArgumentError, 'params must include valid PageSize, PageNumber and UsePaging'
      end

      puts "fetching #{path} with #{params.except('access_token')}. #{fetched.length} results so far."

      results = self.send(method, path, params, model)

      unless results.is_a?(Array)
        raise StandardError, "Result from paginated request to #{path} with params: #{params} is not a collection"
      end

      fetched.concat(results)
      results_length = results.length

      if fetch_all
        if results_length > 0
          # TODO (#111186744): Add logging to see if any pages with less than expected data (as seen in the /appointments endpoint)
          new_params = params.deep_dup
          new_params['PageNumber'] = page_number + 1

          begin
            paginated_request(method: method, path: path, params: new_params, model: model, fetched: fetched)

          # Skip broken pages as a temporary fix for booker api issues. Remove once resolved by Booker!
          rescue Booker::Error => ex
            if ex.try(:response).try(:[], 'Fault').try(:[], 'Detail').try(:[], 'InternalErrorFault').try(:[], 'ErrorCode').to_i == 100000
              #try the next page
              log_issue("Skipping page of #{path} due to API error.",
                                    extra: {
                                        booker_error: ex.error,
                                        booker_error_description: ex.description,
                                        booker_request: ex.request.to_s,
                                        booker_response: ex.response.to_s
                                    }
              )
              new_params['PageNumber'] += 1
              paginated_request(method: method, path: path, params: new_params, model: model, fetched: fetched)
            else
              raise ex
            end
          end
        else
          fetched
        end
      else
        results
      end
    end

    def log_issue(message, extra_info = {})
      if (log_message_block = Booker.config[:log_message])
        log_message_block.call(message, extra_info)
      end
    end

    def get_booker_resources(http_method, path, params=nil, body=nil, booker_model=nil)
      http_options = request_options(params, body)
      puts "BOOKER REQUEST: #{http_method} #{path} #{http_options}" if ENV['BOOKER_API_DEBUG'] == 'true'

      # Allow it to retry the first time unless it is an authorization error
      begin
        booker_resources = handle_errors!(http_options, HTTParty.send(http_method, "#{self.base_url}#{path}", http_options))
      rescue Booker::Error, Net::ReadTimeout => ex
        if ex.is_a? Booker::InvalidApiCredentials
          raise ex
        else
          sleep 1
          booker_resources = nil
        end
      end

      if booker_resources
        results_from_response(booker_resources, booker_model)
      else
        booker_resources = handle_errors!(http_options, HTTParty.send(http_method, "#{self.base_url}#{path}", http_options))

        if booker_resources
          results_from_response(booker_resources, booker_model)
        else
          raise Booker::Error.new(http_options, booker_resources)
        end
      end
    end

    def handle_errors!(request, response)
      puts "BOOKER RESPONSE: #{response}" if ENV['BOOKER_API_DEBUG'] == 'true'

      ex = Booker::Error.new(request, response)
      if ex.error.present? || !response.success?
        case ex.error
          when 'invalid_client'
            raise Booker::InvalidApiCredentials.new(request, response)
          when 'invalid access token'
            get_access_token
            return nil
          else
            raise ex
        end
      end

      response
    end

    def access_token
      if self.temp_access_token && !temp_access_token_expired?
        self.temp_access_token
      else
        get_access_token
      end
    end

    private
      def request_options(query=nil, body=nil)
        options = {
          headers: {
            'Content-Type' => 'application/json; charset=utf-8'
          },
          timeout: 120
        }

        if body.present?
          options[:body] = body
        end

        if query.present?
          options[:query] = query
        end

        options
      end

      def build_resources(resources, booker_model)
        return resources if booker_model.nil?

        if resources.is_a? Hash
          booker_model.from_hash(resources)
        elsif resources.is_a? Array
          booker_model.from_list(resources)
        else
          resources
        end
      end

      def temp_access_token_expired?
        self.temp_access_token_expires_at.nil? || self.temp_access_token_expires_at <= Time.now
      end

      def update_token_store
        if self.token_store && self.token_store_callback_method
          token_store.send(token_store_callback_method, self.temp_access_token, self.temp_access_token_expires_at)
        end
      end

      def results_from_response(response, booker_model=nil)
        return response['Results'] unless response['Results'].nil?

        if booker_model
          model_name = booker_model.to_s.demodulize
          return response[model_name] unless response[model_name].nil?

          pluralized = model_name.pluralize
          return response[pluralized] unless response[pluralized].nil?
        end

        response
      end
  end
end