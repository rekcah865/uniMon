# uniMon
Unify monitor job with docker container( Grafana, InfluxDB)
 
### uniMon script

 
### uniMon in Docker

* Build image(CentOS6.7) which includes cron, oracle 11gR2 client, grafana v2.6, influxdb v0.10.2
	- Download [Oracle 11gR2 client]()
	```
	$ ls -lh linux.x64_11gR2_client.zip 
	-rw-r--r--. 1 docker docker 674M Mar  8 08:16 linux.x64_11gR2_client.zip
	```
	- Edit Oracle Response file: [11gr2_client_install.rsp](11gr2_client_install.rsp)
	- Edit supervisor file: [uniMon_supervisor.conf](uniMon_supervisor.conf)
	- Edit repository file
		- [grafana.repo](grafana.repo)
		- [influxdb.repo](influxdb.repo)
	- Edit Configuration file 
		- [grafana.ini](grafana.ini)
		- [influxdb.conf](influxdb.conf)
		- [oracle.profile](oracle.profile)
	- Edit docker file: [uniMon.dockerfile](uniMon.dockerfile) 

```
$ pwd
/home/docker
$ docker build --rm -t unimon:centos6 -f uniMon.dockerfile .
...
$ docker images unimon:centos6
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
unimon              centos6             4f667c77276a        About an hour ago   4.171 GB
```

* Preparation for container
	- crontab
	- grafana 
	- influxdb	

```
$ sudo mkdir -p /vol/app/grafana_lib /vol/app/grafana_etc /vol/log/grafana_log
$ sudo chmod 777 /vol/app/grafana_lib /vol/app/grafana_etc /vol/log/grafana_log
$ sudo mkdir -p /vol/app/influxdb_lib /vol/app/influxdb_etc /vol/log/influxdb_log
$ sudo chmod 777 /vol/app/influxdb_lib /vol/app/influxdb_etc /vol/log/influxdb_log
$ pwd
/home/docker/uniMon
$ vi crontab
...

```

* Run container

```
$ docker run -d -l uniMon1 --name=uniMon1 -v /vol/app/grafana_lib:/var/lib/grafana -v /vol/app/grafana_etc:/etc/grafana -v /vol/log/grafana_log:/var/log/grafana -v /vol/app/influxdb_lib:/var/lib/influxdb -v /vol/app/influxdb_etc:/etc/influxdb -v /vol/log/influxdb_log:/var/log/influxdb -v /home/docker/uniMon:/uniMon -p 5001:3000 -p 5002:8083 -p 5003:8086 unimon:centos6
...
$ docker ps uniMon1
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                                                                    NAMES
778fd1dcfcc1        unimon:centos6          "/usr/bin/supervisord"   About an hour ago   Up 42 minutes       0.0.0.0:5001->3000/tcp, 0.0.0.0:5002->8083/tcp, 0.0.0.0:5003->8086/tcp   uniMon1
$ docker exec -it uniMon1 /bin/bash
root@778fd1dcfcc1 /]# ps -eaf
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 09:35 ?        00:00:00 /usr/bin/python /usr/bin/supervisord -c /etc/supervisor.conf
root         8     1  0 09:35 ?        00:00:00 su -s /bin/sh -c /usr/bin/influxd -config /etc/influxdb/influxdb.conf >>/var/log/influxdb/influxd.log 2>&1 in
root        10     1  0 09:35 ?        00:00:00 /usr/sbin/crond -n
root        12     1  0 09:35 ?        00:00:00 su -s /bin/sh -c /usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini cfg
grafana     13    12  0 09:35 ?        00:00:00 sh -c /usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini cfg:default.pa
influxdb    14     8  0 09:35 ?        00:00:00 sh -c /usr/bin/influxd -config /etc/influxdb/influxdb.conf >>/var/log/influxdb/influxd.log 2>&1
grafana     15    13  0 09:35 ?        00:00:00 /usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini cfg:default.paths.da
influxdb    16    14  0 09:35 ?        00:00:05 /usr/bin/influxd -config /etc/influxdb/influxdb.conf
root       106     1  0 09:35 ?        00:00:00 /usr/libexec/postfix/master
postfix    107   106  0 09:35 ?        00:00:00 pickup -l -t fifo -u
postfix    108   106  0 09:35 ?        00:00:00 qmgr -l -t fifo -u
root       171     0  0 09:45 ?        00:00:00 /bin/bash
root       213     1  0 10:01 ?        00:00:00 /usr/sbin/anacron -s
```

* Check the status

```
$ ip addr show enp4s0f0
4: enp4s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/ether 78:ac:c0:fe:ad:22 brd ff:ff:ff:ff:ff:ff
    inet 10.40.126.103/24 brd 10.40.126.255 scope global enp4s0f0
       valid_lft forever preferred_lft forever
    inet6 fe80::7aac:c0ff:fefe:ad22/64 scope link 
       valid_lft forever preferred_lft forever
$ docker exec -it uniMon1 /bin/bash
root@778fd1dcfcc1 /]# crontab -l
...
$ curl http://10.40.126.103:5003/query?q=show%20users
{"results":[{"series":[{"columns":["user","admin"]}]}]
$ curl -G '10.40.126.103:5003/query' --data-urlencode "q=show databases"
{"results":[{"series":[{"name":"databases","columns":["name"],"values":[["_internal"]]}]}]}
```
	   
[http://10.40.126.103:5001/](http://10.40.126.103:5001/)
[http://10.40.126.103:5002](http://10.40.126.103:5002)

### Monitor database design

* Database, RPs and CQs

```
$ curl -G http://10.40.126.103:5003/query --data-urlencode "q=CREATE DATABASE unimon"
{"results":[{}]}

CREATE RETENTION POLICY ora_q_weekly ON unimon DURATION 1w RE{LICATION 1 DEFAULT
CREATE CONTINUS QUERY ora_q_1w ON ora_q BEGIN SELECT mean(value) as mean_value,name,host INTO unimon."default".ds_ora_q FROM ora_q GROUP BY time(1w) END

```

* Measurement

```
ora_q,name=<QUEUE>,host=<sid_hostname> value=<VALUE> <TIMESTAMP>

$ curl -i -XPOST 'http://10.40.126.103:5003/write?db=unimon' --data-binary 'ora_q,name=JBUP_QUEUE,db=ods_suzdrprd02 value=0 1457520902000'
HTTP/1.0 204 No Content
Request-Id: ebca9709-e5a2-11e5-801a-000000000000
X-Influxdb-Version: 0.10.2
Date: Wed, 09 Mar 2016 02:59:20 GMT
$ cat test.csv
ora_q,name=EXCEPTION_QUEUE,db=ods_suzdrprd06 value=998 1457521100000
ora_q,name=JBUP_EXCEPTION_QUEUE,db=ods_suzdrprd06 value=0 1457521100000
ora_q,name=PARAM_LOAD_QUEUE,db=ods_suzdrprd06 value=20042 1457521100000
ora_q,name=SIB_EXCEPTION_QUEUE,db=ods_suzdrprd02 value=0 1457521202000
ora_q,name=PARAM_LOAD_QUEUE,db=ods_suzdrprd02 value=1987 1457521202000
ora_q,name=JBUP_QUEUE,db=ods_suzdrprd02 value=0 1457521202000
ora_q,name=JBUP_EXCEPTION_QUEUE,db=ods_suzdrprd02 value=0 1457521202000
ora_q,name=FILE_LOCATOR_PUB_Q,db=ods_suzdrprd02 value=0 1457521202000
ora_q,name=EXCEPTION_QUEUE,db=ods_suzdrprd02 value=0 1457521202000
ora_q,name=FILE_MOVER_Q,db=ods_suzdrprd02 value=0 1457521202000
$ curl -XPOST 'http://10.40.126.103:5003/write?db=unimon' --data-binary @test.csv
$ curl -G http://10.40.126.103:5003/query?db=unimon --data-urlencode "db=unimon" --data-urlencode "q=select * from ora_q"
{"results":[{"series":[{"name":"ora_q","columns":["time","db","name","value"],"values":[["1970-01-01T00:24:17.520902Z","ods_suzdrprd02","JBUP_QUEUE",0],["1970-01-01T00:24:17.5211Z","ods_suzdrprd06","PARAM_LOAD_QUEUE",20042],["1970-01-01T00:24:17.5211Z","ods_suzdrprd06","EXCEPTION_QUEUE",998],["1970-01-01T00:24:17.5211Z","ods_suzdrprd06","JBUP_EXCEPTION_QUEUE",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","FILE_LOCATOR_PUB_Q",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","JBUP_QUEUE",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","JBUP_EXCEPTION_QUEUE",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","EXCEPTION_QUEUE",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","SIB_EXCEPTION_QUEUE",0],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","PARAM_LOAD_QUEUE",1987],["1970-01-01T00:24:17.521202Z","ods_suzdrprd02","FILE_MOVER_Q",0]]}]}]}

```

### Reference

[InfluxDB Installation](https://docs.influxdata.com/influxdb/v0.8/introduction/installation/)
[Grafana RPM Installation](http://docs.grafana.org/installation/rpm)
[Oracle 11gR2 Database Client Installation Guide](https://docs.oracle.com/cd/E11882_01/install.112/e24322/toc.htm)

