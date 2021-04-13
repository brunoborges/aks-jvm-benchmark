FROM maven:3-adoptopenjdk-11 AS mavenBuild
COPY pom.xml /tmp/
COPY src /tmp/src/
WORKDIR /tmp/
RUN mvn package

FROM adoptopenjdk:11
RUN mkdir /usr/local/example
COPY --from=mavenBuild /tmp/target/*.jar /usr/local/example/example.jar
COPY applicationinsights-agent-3.0.2.jar /usr/local/example/
COPY applicationinsights.json /usr/local/example/

COPY start.sh /usr/local/example/start.sh

CMD ["sh", "/usr/local/example/start.sh"]
