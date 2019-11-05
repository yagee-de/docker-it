FROM centos:7 as bootstrap
ARG GECKO_DRIVER=0.26.0
RUN curl -L https://github.com/mozilla/geckodriver/releases/download/v${GECKO_DRIVER}/geckodriver-v${GECKO_DRIVER}-linux64.tar.gz | tar xz -C /usr/local/bin

FROM maven:3-jdk-11 as maven
RUN mvn --version

FROM centos:7 as install
COPY --from=bootstrap /usr/local/bin/geckodriver /usr/local/bin
COPY --from=maven /usr/share/maven /usr/share/maven
ENV CI true
ENV LANG en_US.utf8
ENV _JAVA_OPTIONS="-Djdk.net.URLClassPath.disableClassPathURLCheck=true"
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
RUN groupadd -g 1000 mycore && \
    useradd -m -u 1000 -g mycore mycore
COPY --chown=mycore:mycore toolchains.xml /home/mycore/.m2/
RUN yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm && \
    yum install -y \
	ca-certificates gnupg git subversion which \
        firefox java-11-openjdk-devel java-1.8.0-openjdk-devel && \
    update-alternatives --set java java-11-openjdk.x86_64 && \
    update-alternatives --set javac java-11-openjdk.x86_64 && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    yum clean all && \
    rm -rf -v /var/cache/yum /var/tmp/* && \
    mvn -version
USER mycore
WORKDIR /home/mycore
