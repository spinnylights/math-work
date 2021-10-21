# frozen_string_literal: true

require 'cairo'
require 'pango'

include Cairo::Color

W = 3840
H = 2160

TICK_HEIGHT = 100
LINE_WIDTH  = 20
FONT_SIZE   = 50

def draw_tick(cr, x, y, dashed=false)
  cr.save

  if dashed
    cr.set_dash([TICK_HEIGHT/10])
  end

  cr.move_to(x, y - TICK_HEIGHT/2)
  cr.line_to(x, y + TICK_HEIGHT/2)
  cr.stroke

  cr.restore
end

def draw_text(cr, text, x, y, label_pos)
  cr.save

  p_lay = cr.create_pango_layout
  p_lay.set_text(text)
  font_desc = Pango::FontDescription.new("Mono #{FONT_SIZE}")
  p_lay.font_description = font_desc
  label_point = y - p_lay.pixel_size[1] - 10
  if (label_pos == :below)
    label_point = y + p_lay.pixel_size[1]/1.25
  end
  cr.move_to(x - p_lay.pixel_size[0]/2, label_point)
  cr.show_pango_layout(p_lay)

  cr.restore
end

def draw_interval(cr, inf, sup, y_pos, label="", label_pos=:above, dashed_inf=false, dashed_sup=false)
  cr.save

  draw_tick(cr, dashed_inf ? inf : inf - LINE_WIDTH/2, y_pos , dashed_inf)
  draw_tick(cr, dashed_sup ? sup : sup - LINE_WIDTH/2, y_pos, dashed_sup)

  cr.move_to(inf, y_pos)
  cr.line_to(sup, y_pos)
  cr.stroke

  unless label.empty?
    draw_text(cr, label, inf + (inf - sup).abs/2, y_pos, label_pos)
  end

  cr.restore
end

class MyColors
  def initialize
    fill_inner
  end

  def fill_inner
    @inner = []
    gradations = 20
    (1..gradations).each do |g|
      saturation = 1.0/g
      [saturation, 0.5].repeated_permutation(3).to_a.uniq.each do |rgb|
        @inner << Cairo::Color::RGB.new(*rgb)
      end
    end
  end

  def pop
    color = @inner.pop
    if @inner.empty?
      fill_inner
    end
    color
  end
end

def draw_labelled_tick(cr, text, x_pos, y_pos, label_pos=:below)
  cr.save

  cr.set_source_color($colors.pop)

  draw_tick(cr, x_pos, y_pos)
  draw_text(cr, text, x_pos, y_pos, label_pos)

  cr.restore
end

Tick = Struct.new(:label, :x_pos)

def output_diagram(y_dist)
  data   = nil
  stride = nil

  $colors = MyColors.new

  Cairo::ImageSurface.new(W, H) do |surface|
    cr = Cairo::Context.new(surface)

    cr.set_source_color(WHITE)
    cr.paint

    cr.set_source_color(BLACK)
    cr.set_line_width(LINE_WIDTH)

    line_start = W/8
    line_end   = line_start*7
    line_len   = (line_start - line_end).abs
    line_y     = H/4
    zoom_coef  = 0.0005

    cr.move_to(line_start, line_y)
    cr.line_to(line_end, line_y)
    cr.stroke

    x      = 10
    n      = 3
    y      = (x**(1.0/n)) - (x**(1.0/n))*y_dist
    h_eps  = (x - y**n)/(n*(y+1)**(n-1))
    h      = h = h_eps - h_eps/((h_eps+1)*2)
    if h > 1 then h = 0.9 end

    #puts ((x - y**n)/((n*(y+1))**(n-1)))/zoom_coef

    ticks = []
    ticks << Tick.new("0", 0.0)
    ticks << Tick.new("1", 1.0)
    ticks << Tick.new("x", x)
    ticks << Tick.new("y", y)
    ticks << Tick.new("x-yⁿ", (x - y**n))
    ticks << Tick.new("hn(y+1)ⁿ⁻¹", (h*n*(y+1)**(n-1)))
    ticks << Tick.new("hn(y+h)ⁿ⁻¹", (h*n*(y+h)**(n-1)))
    ticks << Tick.new("(y+h)ⁿ-yⁿ", (y+h)**n - y**n)
    ticks << Tick.new("h", h)
    #ticks << Tick.new("y+h", y+h)
    #ticks << Tick.new("x-yⁿ/n(y+1)ⁿ⁻¹", ((x - y**n)/(n*(y+1)**(n-1))))

    max = ticks.max_by {|t| t.x_pos}.x_pos

    # 0     -> line_start
    # max   -> line_end
    # max/2 -> (line_start - line_end).abs / 2
    scale = Proc.new {|a| (a/max)*line_len + line_start}

    ticks.each do |t|
      draw_labelled_tick(cr, t.label, scale.(t.x_pos), line_y)
    end

    data   = cr.target.data
    stride = cr.target.stride
  end

  Cairo::ImageSurface.new(data, :argb32, W, H, stride) do |surface|
    surface.write_to_png(File.basename(__FILE__, '.rb') + "_#{y_dist}.png")
  end
end

(0..10).each do |n|
  output_diagram(n*0.1)
end
