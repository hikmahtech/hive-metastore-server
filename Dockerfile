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
COPY ./hive/hive-env.sh $HIVE_HOME/conf/hive-env.sh
COPY ./hive/hive-log4j2.properties $HIVE_HOME/conf/hive-log4j2.properties
COPY ./hive/hive-config.sh $HIVE_HOME/bin/hive-config.sh

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

USER root
COPY ./hive/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
USER hadoop

# Hadoop Ports
EXPOSE 9083 10000 10001 10002

ENTRYPOINT [ "/entrypoint.sh" ]