#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive


sed -i 's/HOST_NAME/$HOST_NAME/g' $HIVE_HOME/conf/hive-site.xml
sed -i 's/DATABASE_URL/$DATABASE_URL/g' $HIVE_HOME/conf/hive-site.xml
sed -i 's/DATABASE_DRIVER/$DATABASE_DRIVER/g' $HIVE_HOME/conf/hive-site.xml
sed -i 's/S3_USERNAME/$S3_USERNAME/g' $HIVE_HOME/conf/hive-site.xml
sed -i 's/S3_PASSWORD/$S3_PASSWORD/g' $HIVE_HOME/conf/hive-site.xml
sed -i 's/S3_ENDPOINT/$S3_ENDPOINT/g' $HIVE_HOME/conf/hive-site.xml

$HIVE_HOME/bin/schematool -dbType mysql -initSchema
set -e
$HIVE_HOME/bin/hive --service metastore &
sleep 5
$HIVE_HOME/bin/hive --service hiveserver2 
