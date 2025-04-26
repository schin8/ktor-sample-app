# syntax=docker/dockerfile:1

FROM amazoncorretto:21 as build
WORKDIR /app

# Install Gradle
ENV GRADLE_VERSION=8.4
RUN yum install -y unzip wget \
    && wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && rm gradle-${GRADLE_VERSION}-bin.zip
ENV PATH=$PATH:/opt/gradle-${GRADLE_VERSION}/bin

# Add Gradle optimization
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"

# Copy Gradle files first for better layer caching
COPY --chmod=0755 gradlew .
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
# Use --no-daemon to ensure clean builds
RUN gradle --no-daemon dependencies

FROM build as test
COPY src/ src/
RUN gradle --no-daemon test

FROM build as package
COPY src/ src/
RUN gradle --no-daemon buildFatJar
RUN ls -la /app/build/libs/

FROM amazoncorretto:21-alpine as final
WORKDIR /app
# Add non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
COPY --from=package /app/build/libs/*-all.jar app.jar
EXPOSE 8080
# Add health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q --spider http://localhost:8080 || exit 1
# Use exec form of CMD for proper signal handling
CMD ["java", "-jar", "app.jar"]
