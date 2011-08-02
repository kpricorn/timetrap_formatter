require 'prawn'
module Timetrap
  module Formatters
    class Pdf
      attr_accessor :output
      include Timetrap::Helpers

      def initialize entries
        tt = self

        Prawn::Document.generate("bill.pdf") do

          self.font_size = 9

          @widths = [80, 300, 90, 60]

          head = make_table([["Date", "Notes", "Start - End", "Duration"]], :column_widths => @widths)

          data = []

          def row(date, notes, start_end, duration)
            # Return a Prawn::Table object to be used as a subtable.
            make_table([[date, notes, start_end, duration]]) do |t|
              t.column_widths = @widths
              t.cells.style :borders => [:left, :right], :padding => 2
              t.columns(3).align = :right
            end
          end

          sheets = entries.inject({}) do |h, e|
            h[e.sheet] ||= []
            h[e.sheet] << e
            h
          end
          total_duration = 0
          (sheet_names = sheets.keys.sort).each do |sheet|
            id_heading = Timetrap::CLI.args['-v'] ? 'Id' : '  '
            last_start = nil
            from_current_day = []
            sheets[sheet].each_with_index do |e, i|
              from_current_day << e
              total_duration += e.duration / 60
              data << row(tt.format_date_if_new(e.start, last_start), e.note, "#{e.start ? e.start.strftime('%H:%M') : "n.a."} - #{e.end ? e.end.strftime('%H:%M') : ""}", "%2s:%02d" % [e.duration/3600, (e.duration%3600)/60])
              nxt = sheets[sheet].to_a[i+1]
              last_start = e.start
            end
          end

          total_duration *= 60
          foot = make_table([["", "Total", "", "%2s:%02d" % [total_duration/3600, (total_duration%3600)/60]]], :column_widths => @widths) do |t|
            t.column_widths = @widths
            t.columns(3).align = :right
          end

          # Wrap head and each data element in an Array -- the outer table has only one
          # column.
          table([[head], *(data.map{|d| [d]}), [foot]], :header => true, :row_colors => %w[eeeeee ffffff]) do
            row(0).style(:background_color => 'cccccc')
            cells.style :borders => [:left, :right]
            cells.last.style(:borders => [:left, :right, :bottom])
          end
        end

        self.output = "Rendered pdf"
      end
    end
  end
end

