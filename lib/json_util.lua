local cjson = require("cjson")
local cjson2 = cjson.new()

local JSON_Util = {}

JSON_Util.sendJson = function(obj)
  ngx.header.content_type = 'application/json';
  local callback = ngx.var.arg_callback or ngx.var.arg_cb
  if callback ~= nil then
    ngx.header.content_type = 'application/javascript';
  	ngx.say(callback.."("..cjson2.encode(obj)..");")
  else
  	ngx.say(cjson2.encode(obj))
  end
end


return JSON_Util
