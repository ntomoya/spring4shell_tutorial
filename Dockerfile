FROM tomcat:9.0.59-jdk11-temurin-focal
RUN apt update && apt install maven -y

WORKDIR /tmp
COPY pom.xml /tmp/
COPY src /tmp/src
RUN mvn clean package

RUN mv target/spring4shell-0.0.1-SNAPSHOT.war /usr/local/tomcat/webapps/spring4shell.war

WORKDIR /usr/local/tomcat

EXPOSE 8080
# CMD ["catalina.sh", "run"]
CMD ["catalina.sh", "jpda", "run"]
