return function(s, env)
  if env.engine.context:get_option("ascii_mode")
      or s:get_current_start_position() ~= 0
      or not s.input:match("^[UV]") then return true end
  local seg = Segment(0, #s.input)
  seg.tags = Set { "uv" }
  s:add_segment(seg)
  return false
end
