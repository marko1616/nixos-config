local M = {}
function M.scalar(cp)
  if not cp or cp > 0x10ffff or cp < 0 or (cp >= 0xd800 and cp <= 0xdfff) then
    return nil, "not a Unicode scalar value"
  end
  if cp < 0x20 or (cp >= 0x7f and cp <= 0x9f) then
    return nil, "control characters are not committed"
  end
  return utf8.char(cp)
end
function M.unicode(hex)
  if hex == "" then return nil, "incomplete" end
  if not hex:match("^%x+$") or #hex > 6 then return nil, "expect 1-6 hex digits" end
  return M.scalar(tonumber(hex, 16))
end
function M.gb(hex)
  if hex == "" then return nil, "incomplete" end
  if not hex:match("^%x+$") or #hex > 8 then return nil, "expect GB18030 hex bytes" end
  local bytes = {}
  for pair in hex:gmatch("%x%x") do bytes[#bytes+1] = tonumber(pair, 16) end
  local a, b, c, d = table.unpack(bytes)
  if a and a > 0xfe then return nil, "invalid GB18030 lead byte" end
  if not a or #hex % 2 ~= 0 then return nil, "incomplete" end
  if a <= 0x80 then
    if #hex ~= 2 then return nil, "one character at a time" end
    return M.scalar(a == 0x80 and 0x20ac or a)
  end
  if not b then return nil, "incomplete" end
  if b >= 0x40 and b <= 0xfe and b ~= 0x7f then
    if #hex ~= 4 then return nil, "trailing bytes after a two-byte code" end
    local data = require("marko_uv.gb_data")
    local offset = b < 0x7f and 0x40 or 0x41
    return M.scalar(data.two[(a-0x81)*190 + b-offset + 1])
  end
  if b < 0x30 or b > 0x39 then return nil, "invalid GB18030 second byte" end
  if c and (c < 0x81 or c > 0xfe) then return nil, "invalid GB18030 third byte" end
  if not c or not d then return nil, "incomplete" end
  if d < 0x30 or d > 0x39 then return nil, "invalid GB18030 fourth byte" end
  local pointer = (((a-0x81)*10 + b-0x30)*126 + c-0x81)*10 + d-0x30
  if (pointer > 39419 and pointer < 189000) or pointer > 1237575 then
    return nil, "unassigned GB18030 code"
  end
  if pointer == 7457 then return M.scalar(0xe7c7) end
  local ranges = require("marko_uv.gb_data").ranges
  local lo, hi = 1, #ranges
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    if ranges[mid][1] <= pointer then lo = mid else hi = mid - 1 end
  end
  return M.scalar(ranges[lo][2] + pointer - ranges[lo][1])
end
return M
