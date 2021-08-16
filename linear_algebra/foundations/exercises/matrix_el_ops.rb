# frozen_string_literal: true

require 'matrix'

class Numeric
  def latex
    to_s
  end

  def pprint
    to_s
  end
end

class Rational
  def latex
    if denominator == 1
      return numerator.latex
    end

    start = "\\frac"
    num = ''
    denom = denominator.latex

    if !positive?
      start = '-' + start
      num = (-numerator).latex
    else
      num = numerator.latex
    end

    "#{start}{#{num}}{#{denom}}"
  end

  def pprint
    if denominator == 1
      to_i.to_s
    else
      to_s
    end
  end
end

class Complex
  def latex
    if imaginary == 0
      return real.latex
    end

    r = ''
    if real != 0
      r = real.latex
    end

    i = ''
    if imaginary != 0
      i = 'i'
      if imaginary != 1
        if imaginary == -1
          i = '-' + i
        else
          i = imaginary.latex + 'i'
        end
      end
    end

    sep = ''
    if imaginary.positive? && real != 0
      sep = '+'
    end

    "#{r}#{sep}#{i}"
  end

  def pprint
    if imaginary == 0
      to_r.to_s
    else
      str = to_s
      str.gsub!(/\/1([^0-9])/, '\1')
      str.sub!(/(\+|\-)1i/, '\1i')
      str.sub!(/^0(\+|\-)/, '\1')
      str.sub!(/^\+/, '')
      str
    end
  end
end

class Matrix
  def columns
    @rows.transpose
  end

  def el_op(op, mat=self)
    el_op_mat(op) * mat
  end

  def el_ops(ops)
    mat = self
    ops.each do |op|
      mat = el_op(op, mat)
    end

    mat
  end

  def pprint
    strs = columns
    strs.map! do |col|
      max_str_len = 0

      neg = false
      col.map do |e|
        e = e.pprint

        if e.length > max_str_len
          max_str_len = e.length
        end

        e
      end.map do |e|
        if e.length < max_str_len
          diff = max_str_len - e.length
          e = ' '*diff + e
        end

        ' ' + e
      end
    end

    puts strs.transpose.map {|r| r.inject(:+)}.join("\n")
  end

  def latex
    open = "\\begin{bmatrix}\n"
    close = "\\end{bmatrix}\n"
    indent = ' '*2

    inner = @rows.map do |row|
      indent + row.map {|e| e.latex }.join(' & ')
    end.join("\\\\\n") + "\n"

    open + inner + close
  end

  class << self
    def latex_ops(ops, *mats)
      m = mats

      tex = latex_iter('', m)

      ops.each do |op|
        mats.map! {|mat| mat.el_op(op)}
        tex = latex_iter(tex, mats)
      end

      tex
    end

    private

    def latex_iter(tex, melons)
      indent = ' '*2

      tex += "\\begin{align*}\n"
      matstr = melons
      matstr = matstr.map {|m| m.latex.rstrip}
      matstr = matstr.map {|lat| lat.lines.map {|l| indent + l}.join}
      tex += matstr.join(",\\\n") + "\n"
      tex += "\\end{align*}\n"
    end
  end

  private

  def el_op_proc(indx, val)
    ->(m) { m.send(:[]=, *indx, val); m }
  end

  def el_op_mat(op)
    el_op_proc(*op).call(self.class.identity(column_size))
  end
end
