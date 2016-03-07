##
FROM centos:6.7

MAINTAINER Wei.Shen

## Base setting
RUN echo "proxy=http://10.40.3.249:3128" >> /etc/yum.conf
RUN ln -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo ZONE="Asia/Shanghai" > /etc/sysconfig/clock

## Cron, Postfix, ksh
RUN yum -y install vixie-cron mailx ksh postfix unzip
#sed -ri 's/^#mydomain = domain.tld/mydomain = xxx.com/g' /etc/postfix/main.cf

## Grafana 2.6
RUN yum install -y initscripts fontconfig
RUN export https_proxy=http://10.40.3.249:3128
RUN curl https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0-1.x86_64.rpm -o grafana-2.6.0-1.x86_64.rpm
RUN rpm -ivh grafana-2.6.0-1.x86_64.rpm
RUN groupmod grafana && usermod -g grafana grafana
RUN chown grafana:grafana /etc/grafana /var/log/grafana /var/lib/grafana
VOLUME ["/var/lib/grafana", "/var/log/grafana", "/etc/grafana"]
EXPOSE 3000
 
## InfluxDB 0.10
ADD ./influxdb.repo /etc/yum.repos.d/influxdb.repo
RUN yum install influxdb

## Oracle 11.2 client


ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor.conf"]
