FROM ubuntu:16.04

# Install required software packages:

RUN apt-get update
RUN apt-get install -y -y maven git openjdk-8-jdk openjdk-8-jre-headless tomcat7 postgresql-client

# Expose port 8080 to the client:

EXPOSE 8080

# Register Maven repository from Mainz:

COPY settings.xml /root/.m2/

# Checkout source code and build it:

RUN git clone https://bitbucket.org/medinfo_mainz/samply.mdr.git
WORKDIR /samply.mdr
RUN git submodule init
RUN git submodule update
RUN mvn -P parent clean install
RUN mvn clean install

# Configure the MDR:

RUN mkdir /etc/samply/
COPY mdr.oauth2.xml /etc/samply/mdr.oauth2.xml
COPY mdr.postgres.xml /etc/samply/mdr.postgres.xml

# Add tomcat user, which is required for accessing http://localhost:8080/mdr-gui-1.9.0/admin:

RUN cp /var/lib/tomcat7/conf/tomcat-users.xml /var/lib/tomcat7/conf/tomcat-users.xml.orig
RUN echo "<?xml version='1.0' encoding='utf-8'?>" > /var/lib/tomcat7/conf/tomcat-users.xml 
RUN echo "<tomcat-users>" >> /var/lib/tomcat7/conf/tomcat-users.xml 
RUN echo '<role rolename="mdr-admin"/>' >> /var/lib/tomcat7/conf/tomcat-users.xml 
RUN echo '<user username="mdr" password="mdr" roles="mdr-admin"/>' >> /var/lib/tomcat7/conf/tomcat-users.xml 
RUN echo "</tomcat-users>" >> /var/lib/tomcat7/conf/tomcat-users.xml 

# Deploy the WAR files:

WORKDIR /samply.mdr
RUN cp samply.mdr.gui/target/mdr-gui-1.9.0.war /var/lib/tomcat7/webapps/
RUN cp samply.mdr.rest/target/mdr-rest-3.1.0.war /var/lib/tomcat7/webapps/

CMD /bin/bash
