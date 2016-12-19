-- use ngx.location.capture and HttpRedis2Module to access redis no block
-- do not support pipline
local parser = require 'redis.parser'
local sub = string.sub
local byte = string.byte
local concat = table.concat
local null = ngx.null
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local error = error


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.10'


local commands = {
    "append",            "auth",              "bgrewriteaof",
    "bgsave",            "bitcount",          "bitop",
    "blpop",             "brpop",
    "brpoplpush",        "client",            "config",
    "dbsize",
    "debug",             "decr",              "decrby",
    "del",               "discard",           "dump",
    "echo",
    "eval",              "exec",              "exists",
    "expire",            "expireat",          "flushall",
    "flushdb",           "get",               "getbit",
    "getrange",          "getset",            "hdel",
    "hexists",           "hget",              "hgetall",
    "hincrby",           "hincrbyfloat",      "hkeys",
    "hlen",
    "hmget",             --[[ "hmset", ]]     "hscan",
    "hset",
    "hsetnx",            "hvals",             "incr",
    "incrby",            "incrbyfloat",       "info",
    "keys",
    "lastsave",          "lindex",            "linsert",
    "llen",              "lpop",              "lpush",
    "lpushx",            "lrange",            "lrem",
    "lset",              "ltrim",             "mget",
    "migrate",
    "monitor",           "move",              "mset",
    "msetnx",            "multi",             "object",
    "persist",           "pexpire",           "pexpireat",
    "ping",              "psetex",       --[[ "psubscribe", ]]
    "pttl",
    "publish",      --[[ "punsubscribe", ]]   "pubsub",
    "quit",
    "randomkey",         "rename",            "renamenx",
    "restore",
    "rpop",              "rpoplpush",         "rpush",
    "rpushx",            "sadd",              "save",
    "scan",              "scard",             "script",
    "sdiff",             "sdiffstore",
    "select",            "set",               "setbit",
    "setex",             "setnx",             "setrange",
    "shutdown",          "sinter",            "sinterstore",
    "sismember",         "slaveof",           "slowlog",
    "smembers",          "smove",             "sort",
    "spop",              "srandmember",       "srem",
    "sscan",
    "strlen",       --[[ "subscribe", ]]      "sunion",
    "sunionstore",       "sync",              "time",
    "ttl",
    "type",         --[[ "unsubscribe", ]]    "unwatch",
    "watch",             "zadd",              "zcard",
    "zcount",            "zincrby",           "zinterstore",
    "zrange",            "zrangebyscore",     "zrank",
    "zrem",              "zremrangebyrank",   "zremrangebyscore",
    "zrevrange",         "zrevrangebyscore",  "zrevrank",
    "zscan",
    "zscore",            "zunionstore",       "evalsha"
}


local sub_commands = {
    "subscribe", "psubscribe"
}


local unsub_commands = {
    "unsubscribe", "punsubscribe"
}


local mt = { __index = _M }


function _M:new(redis_uri)
    local t = {}
    setmetatable(t, mt)
	t.uri = redis_uri
	return t
end

local function _do_cmd(self, ...)
    local args = {...}
	local req = parser.build_query(args)
	local res = ngx.location.capture(self.uri, {
		body = req
	})
	
	local success = true;
	if res.status == 200 then  
		local reply, typ = parser.parse_reply(res.body)
		if typ == parser.BAD_REPLY then
			-- res is the textual error message from the parser
			success = false;
		elseif typ == parser.INTEGER_REPLY then
			-- res is an integer, like 3, returned from the redis server
		elseif typ == parser.ERROR_REPLY then
			-- res is the error message from the redis2 server
			success = false;
		elseif typ == parser.STATUS_REPLY then
			-- res is the textual message from the redis server
		elseif typ == parser.BULK_REPLY then
			--- res is a string for the bulk data
		elseif typ == parser.MULTI_BULK_REPLY then
			-- res is a lua (array) table that holds the individual bulks
		end
		
		if success then
			return reply
		else
			return nil, res.body
		end
	else
		return nil, res.body
	end
end


local function _check_subscribed(self, res)
    if type(res) == "table"
       and (res[1] == "unsubscribe" or res[1] == "punsubscribe")
       and res[3] == 0
   then
        self.subscribed = nil
    end
end


for i = 1, #commands do
    local cmd = commands[i]

    _M[cmd] =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end
end


for i = 1, #sub_commands do
    local cmd = sub_commands[i]

    _M[cmd] =
        function (self, ...)
            self.subscribed = true
            return _do_cmd(self, cmd, ...)
        end
end


for i = 1, #unsub_commands do
    local cmd = unsub_commands[i]

    _M[cmd] =
        function (self, ...)
            local res, err = _do_cmd(self, cmd, ...)
            _check_subscribed(self, res)
            return res, err
        end
end


function _M.hmset(self, hashname, ...)
    local args = {...}
    if #args == 1 then
        local t = args[1]

        local n = 0
        for k, v in pairs(t) do
            n = n + 2
        end

        local array = new_tab(n, 0)

        local i = 0
        for k, v in pairs(t) do
            array[i + 1] = k
            array[i + 2] = v
            i = i + 2
        end
        -- print("key", hashname)
        return _do_cmd(self, "hmset", hashname, unpack(array))
    end

    -- backwards compatibility
    return _do_cmd(self, "hmset", hashname, ...)
end


function _M.array_to_hash(self, t)
    local n = #t
    -- print("n = ", n)
    local h = new_tab(0, n / 2)
    for i = 1, n, 2 do
        h[t[i]] = t[i + 1]
    end
    return h
end


function _M.add_commands(...)
    local cmds = {...}
    for i = 1, #cmds do
        local cmd = cmds[i]
        _M[cmd] =
            function (self, ...)
                return _do_cmd(self, cmd, ...)
            end
    end
end


return _M