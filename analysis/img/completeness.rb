# frozen_string_literal: true

require 'cairo'
require 'pango'

include Cairo::Color

W = 3840
H = 2160

TICK_HEIGHT = 100
LINE_WIDTH  = 20

data   = nil
stride = nil

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
  font_size = 100
  font_desc = Pango::FontDescription.new("Mono #{font_size}")
  p_lay.font_description = font_desc
  label_point = y - p_lay.pixel_size[1] - 10
  if (label_pos == :below)
    label_point = y + p_lay.pixel_size[1]/8
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

  cr.move_to(line_start, line_y)
  cr.line_to(line_end, line_y)
  cr.stroke

  a_ns = []

  10.times do
    a_n = rand((line_start + line_len/7)..(line_start + line_len*3/4))
    draw_tick(cr, a_n, line_y)
    a_ns << a_n
  end

  a_ns_mid = a_ns.max - (a_ns.min - a_ns.max).abs/2
  len_of_one = rand(a_ns_mid..(a_ns_mid + a_ns_mid/4))

  draw_interval(cr, a_ns.min, a_ns.max, line_y - TICK_HEIGHT*9/8, "A", :above)
  draw_interval(cr, a_ns.min, len_of_one, line_y + TICK_HEIGHT*9/8, "1", :below)

  draw_text(cr, "a_N₁", len_of_one, line_y + TICK_HEIGHT*20/16, :below)

  next_to_last = a_ns.sort[-2]
  draw_interval(cr, len_of_one, next_to_last, line_y + TICK_HEIGHT*9/8, "<1", :below)

  draw_text(cr, "a_N₁-1", a_ns.min, line_y + TICK_HEIGHT*20/16, :below)

  draw_tick(cr, a_ns.min + len_of_one, line_y)
  draw_text(cr, "a_N₁+1", a_ns.min + len_of_one, line_y + TICK_HEIGHT*20/16, :below)

  draw_interval(cr, a_ns.min, a_ns.min + len_of_one, line_y - TICK_HEIGHT*24/8)
  draw_text(cr, "-M", a_ns.min, line_y - TICK_HEIGHT*27/8, :above)
  draw_text(cr, "M", a_ns.min + len_of_one, line_y - TICK_HEIGHT*27/8, :above)

  draw_interval(cr, a_ns.min, a_ns.max, line_y + TICK_HEIGHT*32/8, "S", :below, false, true)
  draw_text(cr, "b", a_ns.max, line_y + TICK_HEIGHT*36/8, :below)

  eps_pos = rand(a_ns.min..a_ns_mid)
  draw_interval(cr, eps_pos, a_ns.max, line_y + TICK_HEIGHT*56/8, "ε", :above)
  draw_tick(cr, eps_pos + (eps_pos - a_ns.max).abs/2, line_y + TICK_HEIGHT*60/8)
  draw_text(cr, "b-ε/2", eps_pos + (eps_pos - a_ns.max).abs/2, line_y + TICK_HEIGHT*60/8, :below)
  draw_tick(cr, eps_pos + (eps_pos - a_ns.max).abs/2 + 50, line_y + TICK_HEIGHT*60/8)
  draw_text(cr, "\n a_N₂,\n a_N₃", eps_pos + (eps_pos - a_ns.max).abs/2 + 50, line_y + TICK_HEIGHT*60/8, :below)

  draw_tick(cr, a_ns.max + (eps_pos - a_ns.max).abs/2, line_y + TICK_HEIGHT*56/8)
  draw_text(cr, "b+ε/2", a_ns.max + (eps_pos - a_ns.max).abs/2, line_y + TICK_HEIGHT*60/8, :below)

  n_pos = rand((eps_pos + (eps_pos - a_ns.max).abs/2 + 50)..a_ns.max)
  draw_tick(cr, n_pos, line_y + TICK_HEIGHT*60/8)
  draw_text(cr, "a_N", n_pos, line_y + TICK_HEIGHT*60/8, :below)

  data   = cr.target.data
  stride = cr.target.stride
end

Cairo::ImageSurface.new(data, :argb32, W, H, stride) do |surface|
  surface.write_to_png("completeness.png")
end
