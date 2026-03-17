FROM ubuntu:noble AS bootstrap
ARG GECKO_DRIVER=0.36.0
RUN apt-get update && apt-get install -y software-properties-common curl && add-apt-repository -y ppa:mozillateam/ppa \
 && curl -L https://github.com/mozilla/geckodriver/releases/download/v${GECKO_DRIVER}/geckodriver-v${GECKO_DRIVER}-linux64.tar.gz | tar xz -C /usr/local/bin \
 && find /etc/apt/sources.list.d

FROM maven:3-eclipse-temurin AS maven
RUN mvn --version

FROM ubuntu:noble AS install
ARG TARGETARCH
COPY --from=bootstrap /etc/apt/sources.list.d/mozilla* /etc/apt/sources.list.d/
#COPY --from=bootstrap /etc/apt/trusted.gpg.d/mozilla* /etc/apt/trusted.gpg.d/
COPY --from=bootstrap /usr/local/bin/geckodriver /usr/local/bin
COPY --from=maven /usr/share/maven /usr/share/maven
ENV CI=true
ENV JAVA_TOOL_OPTIONS="-Djdk.net.URLClassPath.disableClassPathURLCheck=true -Dwebdriver.firefox.bin=/usr/lib/firefox-esr/firefox-esr"
ENV JAVA_HOME=/usr/lib/jvm/java-25-openjdk-${TARGETARCH}
ENV MAVEN_OPTS=-Xmx3072m
ENV LANG=C.UTF-8
RUN groupmod -n mycore ubuntu && \
    usermod -l mycore -d /home/mycore ubuntu
COPY --chown=mycore:mycore gitconfig /home/mycore/.gitconfig
COPY --chown=mycore:mycore toolchains.xml /home/mycore/.m2/
RUN sed -i "s|TARGETARCH|${TARGETARCH}|g" /home/mycore/.m2/toolchains.xml
RUN apt-get update && apt-get install -y ca-certificates &&\
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
	ca-certificates gnupg git subversion lsof libxss1 socat nmap iproute2 \
        openjdk-25-jdk-headless openjdk-21-jdk-headless openjdk-17-jdk-headless openjdk-11-jdk-headless openjdk-8-jdk-headless && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
        firefox-esr && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    geckodriver --version && mvn --version
USER mycore
WORKDIR /home/mycore
