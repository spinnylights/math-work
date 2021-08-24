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

class ElOpAbstract
  def el_mat(row_size)
    yield(Matrix.identity(row_size))
  end
end

class ElOpMul < ElOpAbstract
  attr_reader :row, :scalar
  def initialize(row:, scalar:)
    @row    = row
    @scalar = scalar
  end

  def el_mat(row_size)
    super do |m|
      m[row,row] = scalar
      m
    end
  end
end

class ElOpAdd < ElOpAbstract
  attr_reader :from, :to, :scalar
  def initialize(from:, to:, scalar:)
    @from   = from
    @to     = to
    @scalar = scalar
  end

  def el_mat(row_size)
    super do |m|
      m[to,from] = scalar
      m
    end
  end
end

class ElOpInter < ElOpAbstract
  attr_reader :row_1, :row_2
  def initialize(row_1, row_2)
    @row_1 = row_1
    @row_2 = row_2
  end

  def el_mat(row_size)
    super do |m|
      m[row_1,row_1] = 0
      m[row_1,row_2] = 1
      m[row_2,row_2] = 0
      m[row_2,row_1] = 1
      m
    end
  end
end

class ElOpNoop < ElOpAbstract
  def el_mat(row_size)
    super do |m|
      m
    end
  end
end

class Matrix
  def columns
    @rows.transpose
  end

  def el_op(op, mat=self)
    op.el_mat(row_size) * mat
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
    def latex_ops(ops, mat, extra_indent=0)
      ops.unshift(ElOpNoop.new)

      ops_slices = []
      ops.each_slice(2) do |ops|
        ops_slices.push(ops)
      end

      tex = ''

      ops_slices.each_with_index do |ops, i|
        mat_block = []
        ops.each do |op|
          mat = mat.el_op(op)
          mat_block.push(mat)
        end
        tex = latex_iter(tex, mat_block, i == ops_slices.length - 1)
      end

      if extra_indent > 0
        tex = tex.lines.map {|l| ' '*extra_indent + l}.join
      end

      tex
    end

    private

    def latex_iter(tex, melons, last=false)
      indent = ' '*2

      tex += "\\begin{align*}\n"
      melons.each_with_index do |m,i|
        tex += m.latex.rstrip.lines.map {|l| indent + l}.join
        if i < melons.length - 1
          tex += "\n" + indent + "\\xrightarrow{}"
        elsif last
          tex += "."
        end
        tex += "\n"
      end
      tex += "\\end{align*}\n"
    end
  end

  private

  def el_op_proc(indx, val)
    ->(m) { m.send(:[]=, *indx, val); m }
  end

  def el_op_mat(op)
    el_op_proc(*op).call(self.class.identity(row_size))
  end
end

require 'symbolic'

module Symbolic
  def pprint
    to_s
  end

  def latex
    LatexPrinter.print(self)
  end

  class Printer
    class << self
      def rational(r)
        r.pprint
      end
    end
  end

  class LatexPrinter < Printer
    class << self
      def rational(r)
        r.latex
      end
    end
  end
end
