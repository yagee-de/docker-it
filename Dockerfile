FROM ubuntu:latest as bootstrap
ARG GECKO_DRIVER=0.23.0
RUN apt-get update && apt-get install -y software-properties-common curl && add-apt-repository -y ppa:mozillateam/ppa \
 && curl -L https://github.com/mozilla/geckodriver/releases/download/v${GECKO_DRIVER}/geckodriver-v${GECKO_DRIVER}-linux64.tar.gz | tar xz -C /usr/local/bin

FROM ubuntu:latest as install
COPY --from=bootstrap /etc/apt/sources.list.d/mozilla* /etc/apt/sources.list.d/
COPY --from=bootstrap /etc/apt/trusted.gpg.d/mozilla* /etc/apt/trusted.gpg.d/
COPY --from=bootstrap /usr/local/bin/geckodriver /usr/local/bin
ENV CI true
ENV LANG C.UTF-8
ENV _JAVA_OPTIONS="-Djdk.net.URLClassPath.disableClassPathURLCheck=true"
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install  --no-install-recommends --no-install-suggests -y \
	firefox-esr openjdk-11-jdk-headless openjdk-8-jdk-headless maven ca-certificates gnupg git subversion && \
    rm -rf -v /var/lib/apt/lists/* /var/cache/apt && \
    groupadd -g 1000 mycore && \
    useradd -m -u 1000 -g mycore mycore && \
    geckodriver --version
USER mycore
COPY --chown=mycore:mycore toolchains.xml /home/mycore/.m2/
WORKDIR /home/mycore
