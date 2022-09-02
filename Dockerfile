FROM maven:3-eclipse-temurin-17 AS mavenBuild
COPY pom.xml /tmp/
COPY src /tmp/src/
WORKDIR /tmp/
RUN mvn package

FROM eclipse-temurin:17
RUN mkdir /usr/local/example
COPY --from=mavenBuild /tmp/target/*.jar /usr/local/example/example.jar
COPY start.sh /usr/local/example/start.sh

CMD ["sh", "/usr/local/example/start.sh"]
