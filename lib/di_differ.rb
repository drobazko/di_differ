# require 'diff/diff'
require 'diff/table_formatter'

module DiDiffer
  class Differ
    attr_reader :diff_arr

    def initialize(file1, file2)
      raise "File #{file1} not found" unless File.exists?(file1)
      raise "File #{file2} not found" unless File.exists?(file2)

      @s1 = File.readlines(file1)
      @s2 = File.readlines(file2)

      clean_data
      
      @matrix = Array.new(@s1.size + 1){ Array.new(@s2.size + 1) { 0 } }
      @diff_arr = []
    end

    def diff(formatter: TableFormatter.new)
      subsequence_matrix
      build_diff_arr
      compaq
      formatter.output(@diff_arr)
    end

    def common_subsequence
      seq = []
      i = @s1.size
      j = @s2.size

      while i >= 0 && j >= 0 do
        if @s1[i-1] == @s2[j-1]
          seq << @s1[i-1]
          i -= 1
          j -= 1
        elsif @matrix[i - 1][j] >= @matrix[i][j - 1]
          i -= 1
        else
          j -= 1
        end
      end

      seq.reverse
    end

    private

    def build_diff_arr(i = nil, j = nil)
      i ||= @s1.size
      j ||= @s2.size

      if i > 0 && j > 0 && @s1[i-1] == @s2[j-1]
        build_diff_arr(i - 1, j - 1)
        @diff_arr << {type: :not_changed, val: @s1[i-1]}
      elsif j > 0 && (i == 0 || @matrix[i][j - 1] >= @matrix[i - 1][j])
        build_diff_arr(i, j - 1)
        @diff_arr << {type: :added, val: @s2[j-1]} 
      elsif i > 0 && (j == 0 || @matrix[i][j - 1] < @matrix[i - 1][j])
        build_diff_arr(i - 1, j)
        @diff_arr << {type: :removed, val: @s1[i-1]} 
      else
        ''
      end
    end

    def compaq
      @diff_arr.each_with_index do |e, i|
        next unless [:added, :removed].include? e[:type]
        next if e.empty?

        paired_elem_index = get_pair_index(i)
        next unless paired_elem_index

        replace_str = ''
        replace_str << (@diff_arr[paired_elem_index][:type] == :added ? e[:val] : @diff_arr[paired_elem_index][:val])
        replace_str << '|'
        replace_str << (@diff_arr[paired_elem_index][:type] == :removed ? e[:val] : @diff_arr[paired_elem_index][:val])

        @diff_arr[i][:val] = replace_str
        @diff_arr[i][:type] = :changed
        @diff_arr[paired_elem_index] = {}
      end
      
      @diff_arr.delete_if(&:empty?)
    end

    def subsequence_matrix
      return if @s1.empty? || @s2.empty?

      @s1.each_with_index do |word1, i|
        i = i.next
        @s2.each_with_index do |word2, j|
          j = j.next

          if word1 == word2
            @matrix[i][j] = @matrix[i-1][j-1] + 1
          elsif @matrix[i-1][j] >= @matrix[i][j-1]
            @matrix[i][j] = @matrix[i-1][j]
          else
            @matrix[i][j] = @matrix[i][j-1]
          end
        end
      end
    end

    def clean_data
      @s1.map!{|v| v.gsub(/\r|\n?/, '').strip}
      @s2.map!{|v| v.gsub(/\r|\n?/, '').strip}
    end
    
    def get_pair_index(elem_index)
      return unless [:added, :removed].include? @diff_arr[elem_index][:type]
      @diff_arr.drop(elem_index + 1).each_with_index do |e, i|
        next if e.empty? 
        return unless [:added, :removed].include? e[:type]
        return i + elem_index + 1 if e[:type] != @diff_arr[elem_index][:type]
      end
      nil
    end  
  end
end
