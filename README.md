# uniMon
Unify monitor job with docker container( Grafana, InfluxDB)
 

 
### Grafana (v2.6)

```
$ pwd
/home/docker
$ mkdir grafana26
$ cd grafana26 && mkdir lib ect log
```

```
 -p 20231:3000 -v /u01/app/grafana25/lib:/var/lib/grafana -v /u01/app/grafana25/etc:/etc/grafana -v /u01/app/grafana25/log:/var/log/grafana 

-p 8083:8083 -p 8086:8086 -v /var/influxdb:/data
-e ADMIN_USER="root" -e INFLUXDB_INIT_PWD="somepassword" -e PRE_CREATE_DB="uniMon"

```

Reference

[Oracle 11gR2 Database Client Installation Guide](https://docs.oracle.com/cd/E11882_01/install.112/e24322/toc.htm)

