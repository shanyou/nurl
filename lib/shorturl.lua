local redis = require "redis2"
local base62 = require "base62"
local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local kUrlCacheKeyPrefix = "url"
local kSUKeyPrefix = "si"
local kSUFieldUrl = "url"
local kRedisIdKey = "SI_IDX" -- id generator

local _M = new_tab(0, 155)
_M._VERSION = '0.1'

local mt = { __index = _M }

--[[
create shorturl class
url_prefix: short url prefix
redis_async_url: async redis url for redis nginx module
]]--
function _M.new(self, redis_async_url)
  local t = {}
  setmetatable(t, mt)
	t.redis = redis:new(redis_async_url)
	return t
end

--[[
pack url to short url
]]--
function _M.pack(self, url)
  local redis = self.redis
  local md5 = ngx.md5(url) -- maybe duplicate
  local cache_key = kUrlCacheKeyPrefix .. ":" .. md5
  local ke, err = redis:exists(cache_key)
	if err then
		ngx.log(ngx.ERR, "failed to connect redis: ", err)
	else
		if ke ~= 1 then
			-- generate new key
      local id = redis:incr(kRedisIdKey)
      -- set cache
      local hkey = kSUKeyPrefix .. ":" .. id
      local hdata = {hkey, kSUFieldUrl, url}
      redis:hmset(unpack(hdata))
      redis:set(cache_key, id)
      return {id = id, url = base62.encode(id)}
    else
      local src = redis:get(cache_key)
      return {id = src, url = base62.encode(src)}
		end
	end
end

function _M.unpack(self, url)
  local redis = self.redis
  if url == nil then return nil end
  local id = base62.decode(url)
  local hkey = kSUKeyPrefix .. ":" .. id
  local res, err = redis:hgetall(hkey)
  if err then
    ngx.log(ngx.ERR, "failed to connect redis: ", err)
  else
    local data = {id = id}
    for i=1, #res, 2 do
			data[res[i]]=res[i+1]
		end
    return data
  end
end
return _M
