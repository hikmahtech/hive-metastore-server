# Use the official Ubuntu Jammy (22.04) as a Parent Image
FROM ubuntu:jammy

# Update Ubuntu Software repository
RUN apt-get update && apt-get -y upgrade

# Install Java and other dependencies
RUN apt-get -y install openjdk-11-jdk wget net-tools vim openssh-server netcat

RUN apt-get -y install sudo

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# Create a hadoop user
RUN addgroup --gid 1000 hadoop && \
    adduser --gecos '' --uid 1000 --gid 1000 hadoop && yes hadoop | passwd hadoop
RUN usermod -aG sudo hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER hadoop
WORKDIR /home/hadoop

# Setup SSH keys for Hadoop
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# Configure SSH connection
RUN echo "Host *\nStrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet" > ~/.ssh/config



# Download Hadoop
COPY ./tars/hadoop-3.3.5.tar.gz hadoop-3.3.5.tar.gz
RUN tar -xzvf hadoop-3.3.5.tar.gz hadoop-3.3.5
RUN sudo mv hadoop-3.3.5 /usr/local/hadoop
RUN rm hadoop-3.3.5.tar.gz
RUN sudo chown -R hadoop:hadoop /usr/local/hadoop

COPY ./tars/apache-hive-4.0.0-alpha-2-bin.tar.gz apache-hive-4.0.0-alpha-2-bin.tar.gz
RUN tar -xzvf apache-hive-4.0.0-alpha-2-bin.tar.gz apache-hive-4.0.0-alpha-2-bin
RUN sudo mv apache-hive-4.0.0-alpha-2-bin /usr/local/hive
RUN rm apache-hive-4.0.0-alpha-2-bin.tar.gz
RUN sudo chown -R hadoop:hadoop /usr/local/hive

# Set Hadoop Environment Variables
ENV HADOOP_HOME /usr/local/hadoop
ENV HIVE_HOME /usr/local/hive
ENV PATH $PATH:$HADOOP_HOME/bin
ENV PATH $PATH:$HADOOP_HOME/sbin
ENV PATH $PATH:$HIVE_HOME/bin

# SSH setup for Hadoop

# Add Hadoop Configurations
# COPY ./configs/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
# COPY ./configs/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
# COPY ./hadoop-hdfs/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh

COPY ./configs/hive-site.xml $HIVE_HOME/conf/hive-site.xml
COPY ./configs/hive-env.sh $HIVE_HOME/conf/hive-env.sh
COPY ./configs/hive-log4j2.properties $HIVE_HOME/conf/hive-log4j2.properties
COPY ./configs/hive-config.sh $HIVE_HOME/bin/hive-config.sh

COPY ./jars/delta-core_2.12-2.1.0.jar $HADOOP_HOME/share/hadoop/common/lib/delta-core_2.12-2.1.0.jar
COPY ./jars/delta-storage-2.1.0.jar $HADOOP_HOME/share/hadoop/common/lib/delta-storage-2.1.0.jar
COPY ./jars/mysql-connector-j-8.0.33.jar $HADOOP_HOME/share/hadoop/common/lib/mysql-connector-java-8.0.33.jar
COPY ./jars/aws-java-sdk-core-1.12.484.jar $HADOOP_HOME/share/hadoop/common/lib/aws-java-sdk-core-1.12.484.jar
COPY ./jars/aws-java-sdk-bundle-1.12.484.jar $HADOOP_HOME/share/hadoop/common/lib/aws-java-sdk-bundle-1.12.484.jar
COPY ./jars/hadoop-common-3.3.5.jar $HADOOP_HOME/share/hadoop/common/lib/hadoop-common-3.3.5.jar
COPY ./jars/hadoop-aws-3.3.5.jar $HADOOP_HOME/share/hadoop/common/lib/hadoop-aws-3.3.5.jar

COPY ./jars/mysql-connector-j-8.0.33.jar $HIVE_HOME/lib/mysql-connector-java-8.0.33.jar
COPY ./jars/delta-hive-assembly_2.11-0.6.0.jar $HIVE_HOME/lib/delta-hive-assembly_2.11-0.6.0.jar
COPY ./jars/aws-java-sdk-core-1.12.484.jar $HIVE_HOME/lib/aws-java-sdk-core-1.12.484.jar
COPY ./jars/aws-java-sdk-bundle-1.12.484.jar $HIVE_HOME/lib/aws-java-sdk-bundle-1.12.484.jar
COPY ./jars/hadoop-common-3.3.5.jar $HIVE_HOME/lib/hadoop-common-3.3.5.jar
COPY ./jars/hadoop-aws-3.3.5.jar $$HIVE_HOME/lib/hadoop-aws-3.3.5.jar


RUN cat>${HIVE_HOME}/conf/hive-site.xml<<EOF \
    <configuration>\
    <property>\
    <name>hive.metastore.uris</name>\
    <value>thrift://HOST_NAME:9083</value>\
    </property>\
    <property>\
    <name>hive.metastore.warehouse.dir</name>\
    <value>s3a://BUCKET_PATH/</value>\
    </property>\
    <property>\
    <name>javax.jdo.option.ConnectionURL</name>\
    <value>DATABASE_URL</value>\
    </property>\
    <property>\
    <name>javax.jdo.option.ConnectionDriverName</name>\
    <value>DATABASE_DRIVER</value>\
    </property>\
    <property>\
    <name>javax.jdo.option.ConnectionUserName</name>\
    <value>S3_USERNAME</value>\
    </property>\
    <property>\
    <name>javax.jdo.option.ConnectionPassword</name>\
    <value>S3_PASSWORD</value>\
    </property>\
    <property>\
    <name>hive.metastore.schema.verification</name>\
    <value>false</value>\
    </property>\
    <property>\
    <name>hadoop.proxyuser.hive.hosts</name>\
    <value>*</value>\
    </property>\
    <property>\
    <name>hive.metastore.event.db.notification.api.auth</name>\
    <value>false</value>\
    </property>\
    <property>\
    <name>hadoop.proxyuser.hive.groups</name>\
    <value>*</value>\
    </property>\
    <property>\
    <name>datanucleus.autoStartMechanism</name>\
    <value>SchemaTable</value>\
    </property>\
    <property>\
    <name>hive.metastore.connect.retries</name>\
    <value>15</value>\
    </property>\
    <property>\
    <name>hive.metastore.disallow.incompatible.col.type.changes</name>\
    <value>false</value>\
    </property>\
    <property>\
    <name>metastore.storage.schema.reader.impl</name>\
    <value>org.apache.hadoop.hive.metastore.SerDeStorageSchemaReader</value>\
    </property>\
    <property>\
    <name>hive.support.concurrency</name>\
    <value>true</value>\
    </property>\
    <property>\
    <name>hive.txn.manager</name>\
    <value>org.apache.hadoop.hive.ql.lockmgr.DbTxnManager</value>\
    </property>\
    <property>\
    <name>hive.compactor.initiator.on</name>\
    <value>true</value>\
    </property>\
    <property>\
    <name>hive.compactor.worker.threads</name>\
    <value>1</value>\
    </property>\
    <property>\
    <name>fs.s3a.connection.ssl.enabled</name>\
    <value>true</value>\
    </property>\
    <property>\
    <name>fs.s3a.endpoint</name>\
    <value>S3_ENDPOINT</value>\
    </property>\
    <property>\
    <name>fs.s3.awsAccessKeyId</name>\
    <value>S3_USERNAME</value>\
    </property>\
    <property>\
    <name>fs.s3.awsSecretAccessKey</name>\
    <value>S3_PASSWORD</value>\
    </property>\
    <property>\
    <name>fs.s3a.access.key</name>\
    <value>S3_USERNAME</value>\
    </property>\
    <property>\
    <name>fs.s3a.secret.key</name>\
    <value>S3_PASSWORD</value>\
    </property>\
    <property>\
    <name>fs.s3a.path.style.access</name>\
    <value>true</value>\
    </property>\
    <property>\
    <name>fs.s3a.impl</name>\
    <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>\
    </property>\
    <property>\
    <name>hive.input.format</name>\
    <value>io.delta.hive.HiveInputFormat</value>\
    </property>\
    <property>\
    <name>hive.tez.input.format</name>\
    <value>io.delta.hive.HiveInputFormat</value>\
    </property>\
    <property>\
    <name>hive.metastore.task.threads.always</name>\
    <value>org.apache.hadoop.hive.metastore.events.EventCleanerTask,org.apache.hadoop.hive.metastore.MaterializationsCacheCleanerTask</value>\
    </property>\
    <property>\
    <name>hive.metastore.expression.proxy</name>\
    <value>org.apache.hadoop.hive.metastore.DefaultPartitionExpressionProxy</value>\
    </property>\
    </configuration>\
    EOF

USER root
COPY ./hive/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
USER hadoop

# Hadoop Ports
EXPOSE 9083 10000 10001 10002

ENTRYPOINT [ "/entrypoint.sh" ]