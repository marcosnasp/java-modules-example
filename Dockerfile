FROM eclipse-temurin:17-jdk as build
RUN addgroup java && adduser --ingroup java --disabled-password java
USER java

WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline
COPY src ./src
RUN ./mvnw package -DskipTests
RUN jdeps --ignore-missing-deps -q \
    --recursive \
    --multi-release 17 \
    --print-module-deps \
    --class-path './target/dependency/*' \
    ./target/java-modules-example-1.0.jar > ./deps.info
RUN jlink \
    --add-modules $(cat ./deps.info) \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output ./myjre

FROM alpine:3.18.3
ENV JAVA_HOME /usr/java/jdk17
ENV PATH $JAVA_HOME/bin:$PATH
COPY --from=build /app/myjre $JAVA_HOME
WORKDIR /app
COPY --from=build /app/target/java-modules-example-1.0.jar /app/
ENTRYPOINT ["java", "-jar", "java-modules-example-1.0.jar"]
