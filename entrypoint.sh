#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive


$HIVE_HOME/bin/schematool -dbType mysql -initSchema
set -e
$HIVE_HOME/bin/hive --service metastore &
sleep 5
$HIVE_HOME/bin/hive --service hiveserver2 
