-- Preserve the upstream filter chain for normal input, bypass it for exact U/V.
local M = {}
function M.init(env)
  env.filters = {}
  local list = env.engine.schema.config:get_list("marko_normal_filters")
  for i = 0, list.size - 1 do
    local name = list:get_value_at(i).value
    env.filters[#env.filters + 1] = assert(Component.Filter(env.engine, "", name))
  end
end
function M.tags_match(seg, env)
  env.active = {}
  if not seg:has_tag("uv") then
    for _, filter in ipairs(env.filters) do
      if filter:applies_to_segment(seg) then
        env.active[#env.active + 1] = filter
      end
    end
  end
  return true
end
function M.func(input, env, candidates)
  for _, filter in ipairs(env.active) do
    input = filter:apply(input, candidates)
  end
  for cand in input:iter() do yield(cand) end
end
return M
