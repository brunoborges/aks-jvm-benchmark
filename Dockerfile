FROM adoptopenjdk:11
RUN mkdir /usr/local/example
COPY target/*.jar /usr/local/example/example.jar
COPY applicationinsights-agent-3.0.2.jar /usr/local/example/
COPY applicationinsights.json /usr/local/example/

COPY start.sh /usr/local/example/start.sh

CMD ["sh", "/usr/local/example/start.sh"]
