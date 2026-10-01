-- Bounded rational arithmetic. No Lua evaluation, shell, or binary-float output.
local M, LIMIT = {}, 1000000000000
local function fail(s) error(s, 0) end
local function gcd(a, b)
  a, b = math.abs(a), math.abs(b)
  while b ~= 0 do a, b = b, a % b end
  return a
end
local function mul(a, b)
  if b ~= 0 and math.abs(a) > LIMIT / math.abs(b) then fail("out of range") end
  return a * b
end
local function rat(n, d)
  if d == 0 then fail("division by zero") end
  if d < 0 then n, d = -n, -d end
  local g = gcd(n, d)
  return {n / g, d / g}
end
local function product(a, b)
  local x, y = gcd(a[1], b[2]), gcd(b[1], a[2])
  return rat(mul(a[1] / x, b[1] / y), mul(a[2] / y, b[2] / x))
end
local function sum(a, b)
  local g = gcd(a[2], b[2])
  local x, y = mul(a[1], b[2] / g), mul(b[1], a[2] / g)
  if math.abs(x + y) > LIMIT then fail("out of range") end
  return rat(x + y, mul(a[2], b[2] / g))
end
local function apply(op, a, b)
  if op == "+" then return sum(a, b) end
  if op == "-" then return sum(a, {-b[1], b[2]}) end
  if op == "*" then return product(a, b) end
  if op == "/" then return product(a, rat(b[2], b[1])) end
  if op == "%" then
    if a[2] ~= 1 or b[2] ~= 1 then fail("modulo needs integers") end
    if b[1] == 0 then fail("division by zero") end
    return {a[1] % b[1], 1}
  end
  if b[2] ~= 1 or math.abs(b[1]) > 12 then fail("exponent must be an integer in -12..12") end
  if b[1] < 0 then a = rat(a[2], a[1]) end
  local out = {1, 1}
  for _ = 1, math.abs(b[1]) do out = product(out, a) end
  return out
end
local function decimal(a)
  local n, d = math.abs(a[1]), a[2]
  local integer = math.floor(n / d)
  local rem, digits = n % d, {}
  for i = 1, 13 do
    rem = rem * 10
    digits[i] = math.floor(rem / d)
    rem = rem % d
    if rem == 0 then break end
  end
  local approximate = #digits == 13
  if approximate then
    local carry = digits[13] >= 5 and 1 or 0
    digits[13] = nil
    for i = 12, 1, -1 do
      local value = digits[i] + carry
      digits[i], carry = value % 10, math.floor(value / 10)
    end
    integer = integer + carry
  end
  while digits[#digits] == 0 do digits[#digits] = nil end
  local s = string.format("%.0f", integer)
  if #digits > 0 then s = s .. "." .. table.concat(digits) end
  if a[1] < 0 and s ~= "0" then s = "-" .. s end
  return s, approximate
end
function M.parse(source)
  if #source > 128 then return nil, "input too long" end
  source = source:gsub("=$", "")
  local function run()
    local pos, depth, token, value = 1, 0
    local function next_token()
      if pos > #source then token = "end"; return end
      local ch = source:sub(pos, pos)
      if ch:match("[%d.]") then
        local raw = source:sub(pos):match("^%d*%.?%d*")
        if raw == "." then fail("incomplete") end
        local whole, frac = raw:match("^(%d*)%.?(%d*)$")
        if #frac > 12 or #whole > 13 then fail("out of range") end
        local n, d = tonumber(whole .. frac), 10 ^ #frac
        if not n or n > LIMIT or d > LIMIT then fail("out of range") end
        value, token, pos = rat(n, d), "number", pos + #raw
      elseif ch:match("^[+*/%%^()%-]$") then
        token, pos = ch, pos + 1
      else fail("unsupported character") end
    end
    local binding = {["+"]=10, ["-"]=10, ["*"]=20, ["/"]=20, ["%"]=20, ["^"]=30}
    local expression
    expression = function(minimum)
      depth = depth + 1
      if depth > 24 then fail("expression too deeply nested") end
      local a
      if token == "number" then a = value; next_token()
      elseif token == "+" or token == "-" then
        local negative = token == "-"
        next_token(); a = expression(25)
        if negative then a = {-a[1], a[2]} end
      elseif token == "(" then
        next_token(); a = expression(0)
        if token == "end" then fail("incomplete") end
        if token ~= ")" then fail("missing closing parenthesis") end
        next_token()
      elseif token == "end" then fail("incomplete")
      else fail("missing operand") end
      while binding[token] and binding[token] >= minimum do
        local op, power = token, binding[token]
        next_token()
        a = apply(op, a, expression(op == "^" and power or power + 1))
      end
      depth = depth - 1
      return a
    end
    next_token()
    local answer = expression(0)
    if token ~= "end" then fail("trailing characters or unmatched parenthesis") end
    return decimal(answer)
  end
  local ok, answer, approximate = pcall(run)
  if not ok then return nil, answer end
  return answer, nil, approximate
end
return M
