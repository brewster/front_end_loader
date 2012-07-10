module FrontEndLoader
  class Experiment
    attr_accessor :domain
    attr_accessor :user_count
    attr_accessor :loop_count
    attr_accessor :default_parameters
    attr_reader :basic_auth_enabled
    attr_reader :basic_auth_user
    attr_reader :basic_auth_password
    attr_reader :screen

    attr_reader :run_start_time
    attr_reader :running
    attr_reader :call_times
    attr_reader :call_error_counts
    attr_reader :call_max_times

    def initialize
      @screen = Screen.new(self)
      @running = false
      @mutex = Mutex.new
      @debug_mutex = Mutex.new
      @loop_count = -1
      @paused = false
      clear_data
    end

    def synchronize(&block)
      @mutex.synchronize do
        block.call
      end
    end

    def debug=(file)
      @debug_file = File.open(file, 'w')
    end

    def write_debug(data)
      if @debug_file
        @debug_mutex.synchronize do
          @debug_file.puts(data)
          @debug_file.flush
        end
      end
    end

    def write_screen_to_debug
      @debug_mutex.synchronize do
        @screen.write_debug(@debug_file)
      end
    end

    def clear_data
      @mutex.synchronize do
        @call_counts ||= Hash.new { |h,k| h[k] = 0 }
        @call_counts.keys.each { |k| @call_counts[k] = 0 }

        @call_times ||= Hash.new { |h,k| h[k] = 0.0 }
        @call_times.keys.each { |k| @call_times[k] = 0.0 }

        @call_max_times ||= Hash.new { |h,k| h[k] = 0.0 }
        @call_max_times.keys.each { |k| @call_max_times[k] = 0.0 }

        @call_error_counts ||= Hash.new { |h,k| h[k] = 0 }
        @call_error_counts .keys.each { |k| @call_error_counts[k] = 0 }

        @call_times_last_25 ||= Hash.new { |h,k| h[k] = [] }
        @call_times_last_25.keys.each { |k| @call_times_last_25[k] = [] }

        @error_counts_by_type ||= Hash.new { |h,k| h[k] = 0 }
        @error_counts_by_type.keys.each { |k| @error_counts_by_type[k] = 0 }

        if @run_start_time
          @run_start_time = Time.now
        else
          @run_start_time = nil
        end
      end
    end

    def basic_auth(user, password)
      @basic_auth_enabled = true
      @basic_auth_user = user
      @basic_auth_password = password
    end

    def requests(&block)
      @request_block = block
    end

    def run
      @running = true
      @run_start_time = Time.now

      threads = (1..user_count).to_a.map do
        Thread.new(self, @request_block) do |experiment, request_block|
          loops_left = experiment.loop_count
          while(loops_left != 0)
            if experiment.paused?
              sleep(0.25)
            elsif experiment.quitting?
              loops_left = 0
            else
              request_manager = RequestManager.new(experiment, experiment.http_session)
              request_block.call(request_manager)
              loops_left -= 1
            end
          end
        end
      end

      threads << Thread.new(self) do |experiment|
        while (!experiment.quitting?)
          if experiment.paused?
            sleep(0.25)
          else
            experiment.screen.refresh
            sleep(0.1)
          end
        end
      end

      threads << Thread.new(self) do |experiment|
        while (!experiment.quitting?)
          ch = Curses.getch
          if ch == 'c'
            experiment.clear_data
          elsif ch == 'd'
            experiment.write_screen_to_debug
          elsif ch == 'p'
            experiment.pause
          elsif ch == 'q'
            experiment.quit
          elsif ch == 's'
            experiment.clear_data
            experiment.go
          end
        end
      end

      begin
        threads.each(&:run)
        threads.each(&:join)
      rescue Interrupt
        @screen.close
      end

      @screen.close
    end
    
    def http_session
      Patron::Session.new.tap do |session|
        session.base_url = domain
        session.insecure = true
        session.max_redirects = 0
        if basic_auth_enabled
          session.auth_type = :basic
          session.username = basic_auth_user
          session.password = basic_auth_password
          session.connect_timeout = 10
          session.timeout = 500
        end
      end
    end

    def paused?
      @paused
    end

    def pause
      @paused = true
    end

    def go
      @paused = false
    end

    def quitting?
      @quitting
    end

    def quit
      @quitting = true
    end

    def time_call(name, &block)
      begin
        start = Time.now
        response = block.call
        time = Time.now - start
        @mutex.synchronize do
          @call_times[name] += time
          @call_max_times[name] = time if time > @call_max_times[name]
          unless response.status >= 200 && response.status < 400
            write_debug(response.body)
            @call_error_counts[name] += 1
            @error_counts_by_type[response.status] += 1
          end
          @call_counts[name] += 1
          @call_times_last_25[name].unshift(time)
          @call_times_last_25[name] = @call_times_last_25[name].slice(0, 25)
        end
        response
      rescue Patron::TimeoutError
        add_timeout(name)
      end
    end

    def add_timeout(name)
      @mutex.synchronize do
        @call_counts[name] += 1
        @call_times[name] += 0
        @call_error_counts[name] += 1
        @error_counts_by_type['Timeout'] += 1
      end
    end

    def call_counts
      @call_counts.dup
    end

    def total_times
      @call_times.dup
    end

    def average_times
      @call_times.keys.inject({}) do |hash, name|
        if @call_counts[name] == 0
          hash[name] = 0.0
        else
          hash[name] = @call_times[name] / @call_counts[name].to_f
        end
        hash
      end
    end

    def max_times
      @call_max_times.dup
    end

    def error_counts
      @call_error_counts.dup
    end

    def error_types
      @error_counts_by_type.dup
    end

    def error_percents
      @call_counts.keys.inject({}) do |hash, name|
        if @call_counts[name] && @call_counts[name] > 0 && @call_error_counts[name] && @call_error_counts[name] > 0
          hash[name] = (@call_error_counts[name].to_f / @call_counts[name].to_f) * 100.0
        else
          hash[name] = 0.0
        end
        hash
      end
    end

    def throughput
      delta = (Time.now - @run_start_time) / 60.0
      @call_counts.keys.inject({}) do |hash, name|
        hash[name] = @call_counts[name].to_f / delta
        hash
      end
    end
  end
end
