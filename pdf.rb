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

          @widths = [80, 80, 50, 240, 80]
          @headers = ["Date", "Start - End", "Duration", "Notes", "Balance"]

          head = make_table([@headers], :column_widths => @widths)

          data = []

          def row(date, start_end, duration, notes, balance)
            # Return a Prawn::Table object to be used as a subtable.
            make_table([[date, start_end, duration, notes, balance]]) do |t|
              t.column_widths = @widths
              t.cells.style :borders => [:left, :right], :padding => 2
              t.columns(4..5).align = :right
            end
          end

          sheets = entries.inject({}) do |h, e|
            h[e.sheet] ||= []
            h[e.sheet] << e
            h
          end
          (sheet_names = sheets.keys.sort).each do |sheet|
            id_heading = Timetrap::CLI.args['-v'] ? 'Id' : '  '
            last_start = nil
            from_current_day = []
            sheets[sheet].each_with_index do |e, i|
              from_current_day << e
              data << row(tt.format_date_if_new(e.start, last_start), "#{e.start ? e.start.strftime('%H:%M') : "n.a."} - #{e.end ? e.end.strftime('%H:%M') : ""}", "%2s:%02d" % [e.duration/3600, (e.duration%3600)/60], e.note, 0)
              nxt = sheets[sheet].to_a[i+1]
              last_start = e.start
            end
          end

          # Wrap head and each data element in an Array -- the outer table has only one
          # column.
          table([[head], *(data.map{|d| [d]})], :header => true, :row_colors => %w[eeeeee ffffff]) do
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

