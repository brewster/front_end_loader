require 'curses'

module FrontEndLoader
  class Screen

    POSITIONS = {
      :count => 0,
      :average_time => 11,
      :max_time => 22,
      :errors => 33,
      :error_percent => 44,
      :throughput => 55
    }

    LENGTHS = {
      :count => 9,
      :average_time => 9,
      :max_time => 9,
      :errors => 9,
      :error_percent => 9,
      :throughput => 12
    }

    TOTAL_LENGTH = 66

    def initialize(experiment)
      @experiment = experiment
      @entry_count = nil
      @longest_name = 0
      Curses.init_screen
      Curses.nonl
      Curses.cbreak
      Curses.noecho
    end

    def refresh
      run_start_time = nil
      names = nil
      counts_by_name = {}
      times_by_name = {}
      average_times_by_name = {}
      max_times_by_name = {}
      error_counts_by_name = {}
      error_counts_by_type = {}
      error_percents_by_name = {}
      throughput_by_name = {}
      total_calls = nil
      total_time = nil
      total_errors = nil
      delta = nil
      max_max_time = nil

      @experiment.synchronize do
        return if !@experiment.running || @experiment.call_counts.empty?

        run_start_time = @experiment.run_start_time.dup
        names = @experiment.call_counts.keys.dup

        counts_by_name = @experiment.call_counts
        times_by_name = @experiment.total_times
        average_times_by_name = @experiment.average_times
        max_times_by_name = @experiment.max_times
        error_counts_by_name = @experiment.error_counts
        error_counts_by_type = @experiment.error_types
        error_percents_by_name = @experiment.error_percents
        throughput_by_name = @experiment.throughput

        total_calls = @experiment.call_counts.values.inject(0) { |s,i| s + i }
        total_time = @experiment.call_times.values.inject(0) { |s,i| s + i }
        total_errors = @experiment.call_error_counts.values.inject(0) { |s,i| s + i }
        max_max_time = @experiment.call_max_times.values.max.round(3).to_s
        delta = (Time.now - @experiment.run_start_time) / 60.0
      end

      if names.count != @entry_count
        @entry_count = names.length
        @longest_name = names.map(&:length).max
        draw_outlines(names)
      end

      first_position = @longest_name + 6
      line = 3
      names.each do |name|
        clear_line(line, first_position)
        Curses.setpos(line, first_position + POSITIONS[:count])
        Curses.addstr(counts_by_name[name].to_s)
        Curses.setpos(line, first_position + POSITIONS[:average_time])
        Curses.addstr(average_times_by_name[name].round(3).to_s)
        Curses.setpos(line, first_position + POSITIONS[:max_time])
        Curses.addstr(max_times_by_name[name].round(3).to_s)
        Curses.setpos(line, first_position + POSITIONS[:errors])
        Curses.addstr(error_counts_by_name[name].to_s)
        Curses.setpos(line, first_position + POSITIONS[:error_percent])
        Curses.addstr(error_percents_by_name[name].round(3).to_s)
        Curses.setpos(line, first_position + POSITIONS[:throughput])
        Curses.addstr(throughput_by_name[name].to_i.to_s)
        line += 1
      end
      line += 1
      clear_line(line, first_position)
      Curses.setpos(line, first_position + POSITIONS[:count])
      Curses.addstr(total_calls.to_s)
      Curses.setpos(line, first_position + POSITIONS[:average_time])
      Curses.addstr((total_time / total_calls.to_f).round(3).to_s)
      Curses.setpos(line, first_position + POSITIONS[:max_time])
      Curses.addstr(max_max_time.to_s)
      Curses.setpos(line, first_position + POSITIONS[:errors])
      Curses.addstr(total_errors.to_s)
      Curses.setpos(line, first_position + POSITIONS[:error_percent])
      Curses.addstr(((total_errors.to_f / total_calls.to_f) * 100.0).round(1).to_s)
      Curses.setpos(line, first_position + POSITIONS[:throughput])
      Curses.addstr((total_calls.to_f / delta).to_i.to_s)

      line += 3
      time = Time.now - run_start_time
      hours = (time / 3600).to_i
      minutes = (time / 60 - (hours * 60)).to_i
      seconds = (time - (minutes * 60 + hours * 3600)).to_i
      Curses.setpos(line, 3)
      Curses.addstr("run time: #{hours}:#{'%02d' % minutes}:#{'%02d' % seconds}")

      line += 2
      error_counts_by_type.each do |type, count|
        erase_line(line)
        Curses.setpos(line, 3)
        Curses.addstr("#{type}: #{count}") 
        line += 1
      end

      Curses.curs_set(0)
      Curses.refresh
    rescue StandardError => e
      puts e.message
      puts e.backtrace.first
    end

    def clear_line(line, first_position)
      Curses.setpos(line, first_position + POSITIONS[:count])
      Curses.addstr(' ' * LENGTHS[:count])
      Curses.setpos(line, first_position + POSITIONS[:average_time])
      Curses.addstr(' ' * LENGTHS[:average_time])
      Curses.setpos(line, first_position + POSITIONS[:max_time])
      Curses.addstr(' ' * LENGTHS[:max_time])
      Curses.setpos(line, first_position + POSITIONS[:errors])
      Curses.addstr(' ' * LENGTHS[:error_percent])
      Curses.setpos(line, first_position + POSITIONS[:error_percent])
      Curses.addstr(' ' * LENGTHS[:error_percent])
      Curses.setpos(line, first_position + POSITIONS[:throughput])
      Curses.addstr(' ' * LENGTHS[:throughput])
    end

    def erase_line(line)
      Curses.setpos(line, 0)
      Curses.addstr(' ' * TOTAL_LENGTH)
    end

    def draw_outlines(names)
      first_position = @longest_name + 6
      Curses.clear
      Curses.setpos(0, 2)
      Curses.addstr('-' * (first_position + TOTAL_LENGTH))
      Curses.setpos(1, 1)
      Curses.addstr(divider_string)
      Curses.setpos(1, 3)
      Curses.addstr('call')
      Curses.setpos(1, first_position + POSITIONS[:count])
      Curses.addstr('count')
      Curses.setpos(1, first_position + POSITIONS[:average_time])
      Curses.addstr('avg time')
      Curses.setpos(1, first_position + POSITIONS[:max_time])
      Curses.addstr('max time')
      Curses.setpos(1, first_position + POSITIONS[:errors])
      Curses.addstr('errors')
      Curses.setpos(1, first_position + POSITIONS[:error_percent])
      Curses.addstr('error %')
      Curses.setpos(1, first_position + POSITIONS[:throughput])
      Curses.addstr('throughput')
      Curses.setpos(2, 2)
      Curses.addstr('-' * (first_position + TOTAL_LENGTH))
      line = 3
      names.each do |name|
        Curses.setpos(line, 1)
        Curses.addstr(divider_string)
        Curses.setpos(line, 3)
        Curses.addstr(name)
        line += 1
      end
      Curses.setpos(line, 1)
      Curses.addstr(divider_string)
      line += 1
      Curses.setpos(line, 1)
      Curses.addstr(divider_string)

      Curses.setpos(line, 3)
      Curses.addstr('TOTAL')
      line += 1
      Curses.setpos(line, 2)
      Curses.addstr('-' * (first_position + TOTAL_LENGTH))
    end

    def divider_string
      first_position = '|' + (' ' * (@longest_name + 2))
      first_position + '|          |          |          |          |          |             |'
    end

    def close
      Curses.curs_set(1)
      Curses::close_screen
    end

    def write_debug(file)
      (0..Curses.rows).each do |row|
        (0..Curses.cols).each do |col|
          Curses.setpos(row, col)
          char = Curses.inch
          file.write(char)
        end
        file.write("\n")
      end
    end
  end
end
