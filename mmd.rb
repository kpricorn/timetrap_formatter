module Timetrap
  module Formatters
    class Mmd
      attr_accessor :output
      include Timetrap::Helpers

      def initialize entries
        self.output = ''
        sheets = entries.inject({}) do |h, e|
          h[e.sheet] ||= []
          h[e.sheet] << e
          h
        end
        (sheet_names = sheets.keys.sort).each do |sheet|
          self.output <<  "Timesheet: #{sheet}\n"
          id_heading = Timetrap::CLI.args['-v'] ? 'Id' : '  '
          self.output <<  "#{id_heading}  Day               |Start     |End       |  Duration |  Notes  |\n"
          self.output <<  "#{id_heading}  ------------------|:--------:|:--------:|:---------:|:-------:|\n"
          last_start = nil
          from_current_day = []
          sheets[sheet].each_with_index do |e, i|
            from_current_day << e
            self.output <<  "%-4s|%s|%s|%s|%s|%s|\n" % [
              (Timetrap::CLI.args['-v'] ? e.id : ''),
              format_date_if_new(e.start, last_start),
              format_time(e.start),
              format_time(e.end),
              format_duration(e.duration),
              e.note
            ]

            nxt = sheets[sheet].to_a[i+1]
            last_start = e.start
          end
          self.output <<  "    Total%43s\n" % format_total(sheets[sheet])
          self.output <<  "\n" unless sheet == sheet_names.last
        end
        if sheets.size > 1
          self.output <<  <<-OUT
-------------------------------------------------------------
          OUT
          self.output <<  "Grand Total%41s\n" % format_total(sheets.values.flatten)
        end
      end
    end
  end
end

