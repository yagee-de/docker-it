FROM ubuntu:jammy as bootstrap
ARG GECKO_DRIVER=0.31.0
RUN apt-get update && apt-get install -y software-properties-common curl && add-apt-repository -y ppa:mozillateam/ppa \
 && curl -L https://github.com/mozilla/geckodriver/releases/download/v${GECKO_DRIVER}/geckodriver-v${GECKO_DRIVER}-linux64.tar.gz | tar xz -C /usr/local/bin

FROM maven:3-eclipse-temurin as maven
RUN mvn --version

FROM ubuntu:jammy as install
ARG TARGETARCH
COPY --from=bootstrap /etc/apt/sources.list.d/mozilla* /etc/apt/sources.list.d/
COPY --from=bootstrap /etc/apt/trusted.gpg.d/mozilla* /etc/apt/trusted.gpg.d/
COPY --from=bootstrap /usr/local/bin/geckodriver /usr/local/bin
COPY --from=maven /usr/share/maven /usr/share/maven
ENV CI true
ENV JAVA_TOOL_OPTIONS="-Djdk.net.URLClassPath.disableClassPathURLCheck=true -Dwebdriver.firefox.bin=/usr/bin/firefox-esr"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-${TARGETARCH}
ENV MAVEN_OPTS=-Xmx3072m
ENV LANG=C.UTF-8
RUN groupadd -g 1000 mycore && \
    useradd -m -u 1000 -g mycore mycore
COPY --chown=mycore:mycore toolchains.xml /home/mycore/.m2/
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt 
RUN apt-get update && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
	ca-certificates gnupg git subversion lsof libxss1 && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt
RUN apt-get update && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
	firefox-esr && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt
RUN apt-get update && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
	openjdk-17-jdk-headless openjdk-11-jdk-headless openjdk-8-jdk-headless && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt && \
    geckodriver --version && mvn --version
USER mycore
WORKDIR /home/mycore
