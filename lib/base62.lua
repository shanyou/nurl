--[[
Base62 encode decode script
]]--

local Base62 = {}
local digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local BASE = digits:len()
Base62.encode = function(n)
  local t = {}
  repeat
      local d = (n % 62) + 1
      n = math.floor(n / 62)
      table.insert(t, 1, digits:sub(d, d))
  until n == 0
  return table.concat(t,"");
end

Base62.decode = function(s)
  local num = 0;
  for i = 1, #s do
    local c = s:sub(i,i)
    local idx = digits:find(c)
    if idx ~= nil then
      num = BASE * num + digits:find(c) - 1
    end
  end
  return num
end

return Base62
