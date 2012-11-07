module FrontEndLoader
  class RequestManager
    def initialize(experiment, session)
      @experiment = experiment
      @session = session
    end

    def get(name, path, params={}, &block)
      Request.new(@experiment, @session, :get, name, path, params, nil, block).run
    end

    def post_multipart(name, path, params = {}, data = "{}", files = nil, &block)
      Request.new(@experiment, @session, :post_multipart, name, path, params, data, files, block).run
    end

    def post(name, path, params={}, data="{}", &block)
      Request.new(@experiment, @session, :post, name, path, params, data, block).run
    end

    def put(name, path, params={}, data="{}", &block)
      Request.new(@experiment, @session, :put, name, path, params, data, block).run
    end

    def delete(name, path, params={}, &block)
      Request.new(@experiment, @session, :delete, name, path, params, nil, block).run
    end

    def debug(data)
      @experiment.write_debug(data)
    end
  end
end
