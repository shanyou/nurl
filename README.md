# nurl [![Build Status](https://travis-ci.org/shanyou/nurl.svg?branch=master)](https://travis-ci.org/shanyou/nurl)

基于Openresty+Redis实现的短链服务

## 短链设计说明
短网址（Short URL）在网络上有很多种设计实现，主要原理是给每一个URL分配一个数字ID号。然后通过进制转换将ID转正62位含有英文字母与数字的字符串。实际上就是将10进制的数转成62进制([0 - 9, a - z, A - Z])组合的62位数
启始值: 14776336 (62^4)

PHP, Java, Golang在网络上有很多种实现方法。最近公司项目需要使用短链服务，在了解原理后从网上找了一些资料，准备基于Nginx+Lua(resty)+Redis实现一个简单的短链接口服务。通过Docker可以实现快速搭建。 整个思路产考《[短链接服务架构设计与实现](https://www.zybuluo.com/zhangnian88123/note/484298)》这篇文章。

## Redis数据库设计
#### 短链对应表
Data type: Hashes

Key: si:<id> 自增的int类型ID

Value:
  url: 图片的原始地址

#### Url地址反向索引(记录已缓存的短链)
Data type: String  

Key: url:<md5(url)> url图片地址的md5值

Value: id 自增的短链Id

### Base62实现ID与字符串转换
```lua
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
```

其中*Base62.encode*实现ID转字符串，*Base62.decode*实现字符串转ID

### resty调用redis的方法
一般情况下通过[lua-resty-redis](https://github.com/openresty/lua-resty-redis)来调用redis, 此过程在nginx中是一个同步过程。整个进程要在nginx lua处理完一次redis请求后才进行下一次调用。本项目通过[redis2-nginx-module](https://github.com/openresty/redis2-nginx-module)与[ngx.location.capture](https://github.com/openresty/lua-nginx-module#ngxlocationcapture)结合的方法使整个redis请求变成异步，能够承载更多的并发。

### http接口说明
/pack?url=<url>

将原始地址转为短链,结果返回json形式的短链字符串

/unpack?url=<shoturl>

将短链字符串转成原始地址

/<shorturl>

直接301或者404短链地址

## 运行方法
```shell
./run.sh
curl "http://localhost:8080/pack?url=https%3A%2F%2Fgithub.com%2Fshanyou%2Fnurl"
curl "http://localhost:8080/10001"
```

## 参考
[短链接服务架构设计与实现](https://www.zybuluo.com/zhangnian88123/note/484298)

[High Performance URL-Shortening with Redis-backed nginx](http://uberblo.gs/2011/06/high-performance-url-shortening-with-redis-backed-nginx)

[Lua base converter](http://stackoverflow.com/questions/3554315/lua-base-converter)

[high performance URL shortener on steroids using nginx, redis and lua](https://gist.github.com/MendelGusmao/2356310)

[6行代码实现一个 id 发号器](http://blog.fulin.org/2015/07/uuid_generator_in_6_lines/)

[业务系统需要怎样的全局唯一ID](http://weibo.com/p/1001603800404851831206)

[短址(short URL)原理及其实现](http://blog.csdn.net/beiyeqingteng/article/details/7706010)

[使用ngx_lua构建高并发应用（1）](http://blog.csdn.net/chosen0ne/article/details/7304192)
