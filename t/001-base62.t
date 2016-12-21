use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: base62 encode
--- http_config
    lua_socket_connect_timeout 3s;
    lua_socket_send_timeout	3s;
    lua_socket_read_timeout	3s;

    #lua package path
    lua_package_path '/data/openresty/nginx/lib/?.lua;/data/openresty/nginx/lib/?/init.lua;;';
    lua_package_cpath '/data/openresty/nginx/lib/?.so;;';

--- config
    location = /encode {
        content_by_lua_block {
          local base62 = require('base62')
          ngx.say(base62.encode(9999))
        }
    }
--- request
GET /encode
--- response_body
2Bh
--- error_code: 200

=== TEST 2: base62 decode
--- http_config
    lua_socket_connect_timeout 3s;
    lua_socket_send_timeout	3s;
    lua_socket_read_timeout	3s;

    #lua package path
    lua_package_path '/data/openresty/nginx/lib/?.lua;/data/openresty/nginx/lib/?/init.lua;;';
    lua_package_cpath '/data/openresty/nginx/lib/?.so;;';

--- config
    location = /decode {
        content_by_lua_block {
          local base62 = require('base62')
          ngx.say(base62.decode('2Bh'))
        }
    }
--- request
GET /decode
--- response_body
9999
--- error_code: 200
