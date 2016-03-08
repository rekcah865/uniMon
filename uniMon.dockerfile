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
ADD ./influxdb.conf /etc/influxdb/influxdb.conf
VOLUME ["/var/lib/influxdb/data","/var/lib/influxdb/wal"]
EXPOSE 8083 8086


## Oracle 11.2 client
RUN mkdir -p /u01/source
ADD ./linux.x64_11gR2_client.zip /u01/source/linux.x64_11gR2_client.zip
RUN cd /u01/source && unzip linux.x64_11gR2_client.zip
RUN groupadd oinstall && useradd -g dba oracle
RUN chown -R oracle:oinstall /u01/source/client
RUN mkdir -p /u01/app/oraInventory /u01/app/oracle
ADD ./11gr2_client_install.rsp /tmp/11gr2_client_install.rsp
RUN chown -R oracle:oinstall /u01/source/client /u01/app/oraInventory /u01/app/oracle /tmp/11gr2_client_install.rsp
RUN yum -y install binutils-2.20.51.0.2-5.11.el6.i686 compat-libcap1-1.10-1.i686 compat-libstdc++-33-3.2.3-69.el6.i686 gcc-4.4.4-13.el6.i686 gcc-c++-4.4.4-13.el6.i686 glibc-2.12-1.7.el6.i686 glibc-devel-2.12-1.7.el6.i686 ksh libgcc-4.4.4-13.el6.i686 libstdc++-4.4.4-13.el6.i686 libstdc++-devel-4.4.4-13.el6.i686 libaio-0.3.107-10.el6.i686 libaio-devel-0.3.107-10.el6.i686 make-3.81-19.el6.i686 sysstat-9.0.4-11.el6.i686
RUN su - oracle -c "/u01/source/client/runInstaller -responseFile /tmp/11gr2_client_install.rsp -silent" 
RUN /u01/app/oraInventory/orainstRoot.sh
RUN /u01/app/oraInventory/orainstRoot.sh
RUN rm -rf /tmp/Ora* /tmp/CVU*



ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor.conf"]
