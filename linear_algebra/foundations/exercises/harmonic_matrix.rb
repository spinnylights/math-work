# frozen_string_literal: true

require_relative 'matrix_el_ops'

class HarmonicMatrix
  class << self
    def defn(i, j)
      if i < 1 || j < 1
        raise ArgumentError, "indices must be 1 or greater"
      end

      Rational(1, i + j - 1)
    end
  end

  attr_reader :size, :inner, :inverse, :symb
  def initialize(size)
    @size = size
    @inner = Matrix.build(size, size) do |row, col|
      self.class.defn(row + 1, col + 1)
    end
    @inverse = Matrix.identity(size)
    @symb = Matrix.build(size, size) do |row, col|
      var(name: "a_#{row+1}#{col+1}")
    end
  end

  def iter(iters)
    (0..iters).each do |k|
      @inner = Matrix.build(size, size) do |row, col|
        if k.even?
          k_p = (k / 2)
          if row == k_p
            c = Rational(1, inner[row,row])
            @inverse[row,col] *= c
            @symb[row,col] *= c
            c * inner[row,col]
          else
            inner[row,col]
          end
        else
          k_p = ((k - 1) / 2)
          if row == k_p
            inner[row,col]
          else
            c = inner[row,k_p]
            @inverse[row,col] -= c*inverse[k_p,col]
            @symb[row,col] -= c*inverse[k_p,col]
            inner[row,col] - c*inner[k_p,col]
          end
        end
      end
    end

    self
  end

  def pprint(print_inv: true, print_symb: true)
    inner.pprint

    if print_inv
      print "\n"
      inverse.pprint
    end

    if print_symb
      print "\n"
      symb.pprint
    end

    puts "\n***"
  end
end

