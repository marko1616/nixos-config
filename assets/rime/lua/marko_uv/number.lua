local M = {}
local small = {"零","一","二","三","四","五","六","七","八","九"}
local large = {"零","壹","贰","叁","肆","伍","陆","柒","捌","玖"}
function M.digits(s, year)
  return (s:gsub("%d", function(d)
    return year and d == "0" and "〇" or small[tonumber(d) + 1]
  end))
end
function M.integer(s, capital)
  s = s:gsub("^0+", "")
  if s == "" then return "零" end
  if #s > 20 then return nil end
  local digits, units = capital and large or small,
    capital and {"", "拾", "佰", "仟"} or {"", "十", "百", "千"}
  local groups, big = {}, {"", "万", "亿", "兆", "京"}
  while #s > 0 do
    local start = math.max(1, #s - 3)
    table.insert(groups, s:sub(start)); s = s:sub(1, start - 1)
  end
  local out, gap = "", false
  for i = #groups, 1, -1 do
    local group = groups[i]
    if tonumber(group) == 0 then gap = out ~= ""
    else
      if out ~= "" and (gap or tonumber(group) < 1000) then out = out .. "零" end
      local part, zero = "", false
      for j = 1, #group do
        local n = tonumber(group:sub(j, j))
        if n == 0 then zero = part ~= ""
        else
          if zero then part = part .. "零" end
          part = part .. digits[n + 1] .. units[#group - j + 1]
          zero = false
        end
      end
      out, gap = out .. part .. big[i], false
    end
  end
  if not capital then out = out:gsub("^一十", "十") end
  return out
end
function M.candidates(source)
  local sign, whole, dot, fraction = source:match("^([+-]?)(%d+)(%.?)(%d*)$")
  if not whole or (dot == "" and fraction ~= "") then return nil end
  if #whole > 20 or #fraction > 32 then return nil, "too many digits" end
  local prefix = sign == "-" and "负" or ""
  local normal, capital = M.integer(whole), M.integer(whole, true)
  local decimal = dot == "." and "点" .. M.digits(fraction) or ""
  local result = {
    {text=prefix .. normal .. decimal, comment="中文数字"},
    {text=prefix .. capital .. (dot == "." and "点" .. (fraction:gsub("%d", function(d) return large[tonumber(d)+1] end)) or ""), comment="大写数字"},
    {text=prefix .. M.digits(whole) .. decimal, comment="逐位读数"},
  }
  if #fraction <= 2 then
    local j, f = tonumber(fraction:sub(1,1)) or 0, tonumber(fraction:sub(2,2)) or 0
    local money = prefix .. capital .. "元"
    if j == 0 and f == 0 then money = money .. "整"
    else
      if j > 0 then money = money .. large[j+1] .. "角"
      elseif tonumber(whole) ~= 0 then money = money .. "零" end
      if f > 0 then money = money .. large[f+1] .. "分" end
    end
    result[#result+1] = {text=money, comment="金额大写"}
  end
  return result
end
return M
