local M = {}
local ACCEPTED, NOOP = 1, 2
local keypad = { [0xffaa]="*", [0xffab]="+", [0xffad]="-", [0xffae]=".", [0xffaf]="/" }
local function commit(ctx, engine, index)
  local seg = ctx.composition:back()
  local cand = seg and seg:get_candidate_at(index or seg.selected_index)
  if cand then engine:commit_text(cand.text); ctx:clear() end
end
function M.func(key, env)
  local ctx, k = env.engine.context, key.keycode
  if key:release() then return NOOP end
  if ctx:get_option("ascii_mode") then return NOOP end
  local mode = ctx.input:match("^([UV])")
  if not mode then
    if ctx:is_composing() or not key:shift() or key:caps()
        or key:ctrl() or key:alt() or key:super() then return NOOP end
    if k == 85 or k == 117 then ctx:push_input("U"); return ACCEPTED end
    if k == 86 or k == 118 then ctx:push_input("V"); return ACCEPTED end
    return NOOP
  end
  local seg = ctx.composition:back()
  if key:alt() or key:super() then return NOOP end
  local page = env.engine.schema.page_size
  if key:ctrl() then
    if k == 0xff0d then -- Explicit raw commit; Return alone selects a candidate.
      env.engine:commit_text(ctx.input); ctx:clear(); return ACCEPTED
    elseif k >= 49 and k <= 57 then
      local base = seg and math.floor(seg.selected_index / page) * page or 0
      if k - 48 <= page then commit(ctx, env.engine, base + k - 49) end
      return ACCEPTED
    elseif k == 0xff08 then ctx:clear(); return ACCEPTED end
    return NOOP
  end
  if k == 0xff1b then ctx:clear(); return ACCEPTED end
  if k == 0xff08 then
    if #ctx.input == 1 then ctx:clear()
    elseif ctx.caret_pos > 1 then ctx:pop_input(1) end
    return ACCEPTED
  end
  if k == 0xffff then ctx:delete_input(1); return ACCEPTED end
  if k == 0xff51 then ctx.caret_pos = math.max(1, ctx.caret_pos - 1); return ACCEPTED end
  if k == 0xff53 then ctx.caret_pos = math.min(#ctx.input, ctx.caret_pos + 1); return ACCEPTED end
  if k == 0xff50 then ctx.caret_pos = 1; return ACCEPTED end
  if k == 0xff57 then ctx.caret_pos = #ctx.input; return ACCEPTED end
  local delta = ({[0xff52]=-1, [0xff54]=1, [0xff55]=-page, [0xff56]=page})[k]
  if delta then
    if seg then
      local target = math.max(0, seg.selected_index + delta)
      if seg:get_candidate_at(target) then seg.selected_index = target end
    end
    return ACCEPTED
  end
  if k == 32 or k == 0xff0d or k == 0xff8d then
    commit(ctx, env.engine); return ACCEPTED
  end
  local ch = k >= 0x21 and k <= 0x7e and string.char(k) or keypad[k]
  if k >= 0xffb0 and k <= 0xffb9 then ch = tostring(k - 0xffb0) end
  if ch then
    if mode == "U" and ch:match("^[1-9]$") then
      local n = tonumber(ch)
      local base = seg and math.floor(seg.selected_index / page) * page or 0
      if n <= page then commit(ctx, env.engine, base + n - 1) end
    elseif #ctx.input < 129 and
        ((mode == "U" and ch:match("^[a-zA-Z']$")) or
         (mode == "V" and ch:match("^[a-zA-Z0-9.+*/%%^():=%-]$"))) then
      ctx:push_input(ch)
    end
    return ACCEPTED -- Never let punctuation commit an unfinished expression.
  end
  return NOOP
end
return M
