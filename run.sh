#!/bin/bash
docker-compose build
docker-compose stop
docker-compose rm -f
docker-compose up -d
docker exec -it nurl_redis_server_1 redis-cli set "SI_IDX" 14776336
