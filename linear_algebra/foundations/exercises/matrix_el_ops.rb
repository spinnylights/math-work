# frozen_string_literal: true

require 'matrix'

class Matrix
  def columns
    @rows.transpose
  end

  def el_ops(ops)
    mat = self
    ops.each do |op|
      mat = el_op(*op).call(self.class.identity(3)) * mat
    end

    mat
  end

  def pprint
    strs = columns
    strs.map! do |col|
      max_str_len = 0

      neg = false
      col.map do |e|
        if e.respond_to?(:denominator) && e.denominator == 1
          e = e.to_i
        end

        e = e.to_s

        if e[0] == '-'
          neg = true
        end

        if e.length > max_str_len
          max_str_len = e.length
        end

        e
      end.map do |e|
        spacer = ' '

        if e.length < max_str_len
          diff = max_str_len - e.length
          e = ' '*diff + e
        elsif neg && e[0] != '-'
          spacer += ' '
        end

        spacer + e
      end
    end

    puts strs.transpose.map {|r| r.inject(:+)}.join("\n")
  end

  private

  def el_op(indx, val)
    ->(m) { m.send(:[]=, *indx, val); m }
  end
end
