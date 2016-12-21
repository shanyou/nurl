# openresty data volume used to mount as volume with openresty
# Image name: resty
# create: 2016-12-19
# Author: shanyou
FROM centos
MAINTAINER shanyou
LABEL appname="resty"
RUN yum install -y wget curl
RUN yum groupinstall -y 'Development Tools' \
&& yum install -y readline-devel pcre-devel openssl-devel

# change time zone
RUN rm /etc/localtime \
&& ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV RESTY_VERSION 1.11.2.2
ENV RESTY_PREFIX  /data/openresty

#install openresty
RUN cd /tmp ; wget https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz
RUN cd /tmp && tar xvzf openresty-${RESTY_VERSION}.tar.gz
RUN cd /tmp/openresty-* ; ./configure --prefix=${RESTY_PREFIX} \
  --with-pcre-jit \
  --with-cc-opt="-I/usr/local/include" \
  --with-ld-opt="-L/usr/local/lib" \
  --with-http_stub_status_module \
&& make \
&& make install

VOLUME ["$RESTY_PREFIX/nginx/logs"]
EXPOSE 80 443
WORKDIR ${RESTY_PREFIX}/nginx

ADD conf/    $RESTY_PREFIX/nginx/conf
ADD lib/     $RESTY_PREFIX/nginx/lib

# add Test::Nginx perl module
RUN yum install perl-ExtUtils-Embed cpan -y
RUN yum install -y perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
RUN yum install -y "perl(Test::Builder)" "perl(HTTP::Response)" "perl(LWP::UserAgent)" "perl(List::MoreUtils)" \
"perl(Test::LongString)" "perl(Text::Diff)" "perl(URI::Escape)" "perl(URI::Escape)" "perl(Algorithm::Diff)"
RUN echo yes | cpan; exit 0
RUN (echo o conf urllist unshift http://mirrors.163.com/cpan/; echo o conf commit;) | cpan; exit 0
RUN cpan Test::LongString
RUN cpan Test::Base
RUN cpan Test::Nginx
# add test shell
ADD script/go.sh  ${RESTY_PREFIX}/nginx
CMD ["./sbin/nginx"]
