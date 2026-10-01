local vmode = require("marko_uv.vmode")
local symbols = require("marko_uv.symbols")
local M = {}
function M.init(env)
  env.stroke = assert(Component.Translator(env.engine, "uv_stroke", "table_translator"))
  env.radical = assert(Component.Translator(env.engine, "uv_radical", "table_translator"))
end
local function source(backend, code, seg, label)
  -- Query using the engine-owned segment (also works with older Lua bindings).
  -- All returned spans are replaced with the full outer span before yielding.
  local tr = backend:query(code, seg)
  if not tr then return {label=label} end
  local next_item, state = tr:iter()
  return {label=label, next_item=next_item, state=state, head=next_item(state)}
end
local function advance(stream)
  stream.head = stream.next_item(stream.state)
end
function M.func(input, seg, env)
  -- A lua_translator receives a const Segment: never write to seg here.
  if not seg:has_tag("uv") then return end
  local function emit(text, label)
    local cand = Candidate("uv", seg.start, seg._end, text, label)
    cand.preedit = input
    yield(cand)
  end
  local body = input:sub(2)
  if input:sub(1,1) == "V" then
    local candidates = vmode.parse(body)
    for _, item in ipairs(candidates) do emit(item.text,item.comment) end
    return
  end
  body = body:lower()
  if body == "" then return end
  local category = symbols[body]
  if category then
    for _, text in ipairs(category.items) do emit(text, category.name) end
    return
  end
  local streams = {}
  if body:match("^[hspnz]+$") then streams[#streams+1] = source(env.stroke,body,seg,"笔画") end
  streams[#streams+1] = source(env.radical,body,seg,"部件")
  local seen = {}
  local function output(stream)
    local cand = stream.head
    if not seen[cand.text] then
      seen[cand.text] = true
      emit(cand.text,stream.label .. (cand.type == "completion" and "·补全" or ""))
    end
    advance(stream)
  end
  -- Native table streams put exact matches before completions.
  for _, stream in ipairs(streams) do
    while stream.head and stream.head.type ~= "completion" do output(stream) end
  end
  -- Lazy round-robin: neither source starves; no arbitrary candidate truncation.
  while true do
    local any = false
    for _, stream in ipairs(streams) do
      if stream.head then any = true; output(stream) end
    end
    if not any then break end
  end
end
return M
