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
	- Edit docker file: [uniMon.dockerfile](uniMon.dockerfile) 

```
$ pwd
/home/docker
$ docker build --rm -t unimon:centos6 -f uniMon.dockerfile .
...
$ docker images unimon:centos6

```

* Preparation for container
	- crontab
	- ora.env
	- grafana 
	- influxdb
	

```
$ mkdir -p /vol/grafana_lib /vol/grafana_etc /vol/influxdb
$ pwd
/home/docker/uniMon
$ vi crontab
...
$ vi ora.env
...

```

* Run container

```
$ docker run -d -l uniMon1 --name=uniMon1 -v /home/docker/uniMon/grafana_lib:/var/lib/grafana -v /home/docker/uniMon/grafana_etc:/etc/grafana -v /home/docker/uniMon/influxdb:/var/lib/influxdb -p 5001:3000 -p 5002:8083 -p 5003:8086
...
$ docker ps

$ docker exec -it uniMon1 /bin/bash
# ps -eaf
..
```

* Check 

http://localhost:5001/
http://localhost:5002


### Reference

[Grafana RPM Installation](http://docs.grafana.org/installation/rpm)
[Oracle 11gR2 Database Client Installation Guide](https://docs.oracle.com/cd/E11882_01/install.112/e24322/toc.htm)

