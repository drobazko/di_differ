class TableFormatter
  def output(diff_arr)
    diff_arr.each_with_index do |e, i|
      print i + 1
      print ' '
      print case e[:type]
        when :changed
          '*'
        when :removed
          '-'
        when :added
          '+'
        else
          ' '
      end
      print ' '
      print e[:val]
      print "\n"
    end;nil
  end
end
