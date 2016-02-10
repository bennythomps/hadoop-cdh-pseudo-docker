FROM nimmis/java-centos:oracle-8-jdk
MAINTAINER Martin Chalupa <chalimartines@gmail.com>

#Base image doesn't start in root
WORKDIR /

#Add the CDH 5 repository
COPY conf/cloudera.repo  /etc/yum.repos.d/cloudera.repo

#Add a Repository Key
RUN rpm --import https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/RPM-GPG-KEY-cloudera && \
    yum update

#Install CDH package and dependencies
RUN yum install -y zookeeper-server && \
    yum install -y hadoop-conf-pseudo && \
    yum install -y oozie && \
    yum install -y python27 && \
    yum install -y hue && \
    yum install -y hue-plugins

#Install Spark 1.5
RUN wget http://mirrors.ocf.berkeley.edu/apache/spark/spark-1.5.1/spark-1.5.1-bin-without-hadoop.tgz && \
    tar xzf spark-1.5.1-bin-without-hadoop.tgz && \
    rm *.tgz && \
    mv spark-1.5.1* /usr/lib/spark && \
    ln -s /usr/lib/spark/bin/spark-shell /usr/bin/spark-shell && \
    ln -s /usr/lib/spark/bin/spark-submit /usr/bin/spark-bin && \
    mkdir /etc/spark/conf

#Copy updated config files
COPY conf/core-site.xml /etc/hadoop/conf/core-site.xml
COPY conf/hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml
COPY conf/mapred-site.xml /etc/hadoop/conf/mapred-site.xml
COPY conf/hadoop-env.sh /etc/hadoop/conf/hadoop-env.sh
COPY conf/yarn-site.xml /etc/hadoop/conf/yarn-site.xml
COPY conf/fair-scheduler.xml /etc/hadoop/conf/fair-scheduler.xml
COPY conf/oozie-site.xml /etc/oozie/conf/oozie-site.xml
COPY conf/spark-defaults.conf /etc/spark/conf/spark-defaults.conf
COPY conf/hue.ini /etc/hue/conf/hue.ini

#Format HDFS
RUN su -c 'hdfs namenode -format' - hdfs

COPY conf/run-hadoop.sh /usr/bin/run-hadoop.sh
RUN chmod +x /usr/bin/run-hadoop.sh

RUN su oozie /usr/lib/oozie/bin/ooziedb.sh create -run && \
    wget http://archive.cloudera.com/gplextras/misc/ext-2.2.zip -O ext.zip && \
    unzip ext.zip -d /var/lib/oozie

#uninstall not necessary hue apps
RUN /usr/lib/hue/tools/app_reg/app_reg.py --remove impala && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove beeswax && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove search && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove sqoop && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove rdbms && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove metastore && \
    /usr/lib/hue/tools/app_reg/app_reg.py --remove security

# NameNode (HDFS)
EXPOSE 8020 50070

# DataNode (HDFS)
EXPOSE 50010 50020 50075

# ResourceManager (YARN)
EXPOSE 8030 8031 8032 8033 8088

# NodeManager (YARN)
EXPOSE 8040 8042

# JobHistoryServer
EXPOSE 10020 19888

# Hue
EXPOSE 8888

# Spark history server
EXPOSE 18080

# Technical port which can be used for your custom purpose.
EXPOSE 9999

CMD ["/usr/bin/run-hadoop.sh"]
