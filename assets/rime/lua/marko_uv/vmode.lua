local number = require("marko_uv.number")
local codec = require("marko_uv.codec")
local calc = require("marko_uv.calc")
local M = {}
local function result(items, hint)
  local seen, out = {}, {}
  for _, item in ipairs(items or {}) do
    if not seen[item.text] then out[#out+1] = item; seen[item.text] = true end
  end
  return out, hint
end
function M.parse(body)
  if body == "" then return {}, "number / 2026.9.30 / 12:34 / 1+2 / UC7389 / GBD3F1" end
  local lower = body:lower()
  if lower == "u" or lower == "g" then return {}, "type UC or GB" end
  local prefix = lower:sub(1,2)
  if prefix == "uc" or prefix == "gb" then
    local text, err = (prefix == "uc" and codec.unicode or codec.gb)(body:sub(3))
    if not text then return {}, err end
    return {{text=text, comment=prefix == "uc" and "Unicode" or "GB18030 (WHATWG)"}}
  end
  -- Two dots reserve the date grammar, including incomplete/invalid dates.
  if body:match("^%d+%.%d*%.") then
    local y, m, d = body:match("^(%d%d%d%d)%.(%d%d?)%.(%d%d?)$")
    if not y then return {}, "date format: YYYY.M.D" end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    local days = {31,28,31,30,31,30,31,31,30,31,30,31}
    if y % 400 == 0 or (y % 4 == 0 and y % 100 ~= 0) then days[2] = 29 end
    if y < 1 or not days[m] or d < 1 or d > days[m] then return {}, "no such date" end
    return result({
      {text=string.format("%d年%d月%d日",y,m,d), comment="日期"},
      {text=number.digits(string.format("%04d",y),true).."年"..number.integer(tostring(m)).."月"..number.integer(tostring(d)).."日", comment="中文日期"},
      {text=string.format("%04d-%02d-%02d",y,m,d), comment="ISO 日期"},
    })
  end
  if body:find(":",1,true) then
    local h, m, s = body:match("^(%d%d?):(%d%d?):(%d%d?)$")
    if not h then h, m = body:match("^(%d%d?):(%d%d?)$") end
    if not h then return {}, "time format: H:M[:S]" end
    h, m, s = tonumber(h), tonumber(m), s and tonumber(s)
    if h > 23 or m > 59 or (s and s > 59) then return {}, "time out of range" end
    local chinese = number.integer(tostring(h)).."时"..number.integer(tostring(m)).."分"
    local digital = string.format("%02d:%02d",h,m)
    if s then chinese = chinese..number.integer(tostring(s)).."秒"; digital = digital..string.format(":%02d",s) end
    return result({{text=chinese,comment="中文时间"},{text=digital,comment="时间"}})
  end
  if body:match("^[+-]?%d+%.?%d*$") then
    if body:sub(-1) == "." then return {}, "keep typing a decimal or a date" end
    local candidates, err = number.candidates(body)
    return result(candidates, err)
  end
  local answer, err, approximate = calc.parse(body)
  if not answer then return {}, err end
  return result({
    {text=answer,comment=approximate and "约值 · 小数 12 位" or "计算结果"},
    {text=body:gsub("=$", "").."="..answer,comment="算式"},
  })
end
return M
