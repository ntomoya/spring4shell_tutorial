FROM tomcat:9.0.59-jdk11-temurin-focal
RUN sed -i 's@archive.ubuntu.com@ftp.jaist.ac.jp/pub/Linux@g' /etc/apt/sources.list && \
    apt update && \
    apt install maven -y

WORKDIR /tmp
COPY pom.xml /tmp/
RUN mvn verify clean --fail-never

COPY src /tmp/src
RUN mvn package

RUN mv target/spring4shell-0.0.1-SNAPSHOT.war /usr/local/tomcat/webapps/spring4shell.war

WORKDIR /usr/local/tomcat

EXPOSE 8080
# CMD ["catalina.sh", "run"]
CMD ["catalina.sh", "jpda", "run"]
