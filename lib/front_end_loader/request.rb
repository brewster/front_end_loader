module FrontEndLoader
  class Request
    def initialize(experiment, session, method, name, path, params, data, response_block)
      @experiment = experiment
      @session = session
      @method = method
      @name = name
      @path = path

      @headers = @experiment.default_headers || {}

      param_hash = @experiment.default_parameters ? @experiment.default_parameters.merge(params) : params
      @params = URI.encode(param_hash.map { |k,v| "#{k}=#{v}" }.join('&'))

      @data = data
      @response_block = response_block
    end

    def run
      response = nil
      if [:get, :delete].include?(@method)
        response = @experiment.time_call(@name) do
          @session.__send__(@method, "#{@path}?#{@params}", @headers)
        end
      else
        response = @experiment.time_call(@name) do
          @session.__send__(@method, "#{@path}?#{@params}", @data, @headers)
        end
      end
      if @response_block && response.is_a?(Patron::Response)
        @response_block.call(response)
      end
    end
  end
end
