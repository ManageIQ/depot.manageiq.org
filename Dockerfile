FROM manageiq/ruby

ENV RAILS_ENV=production

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install centos-release-scl-rh &&         \
    yum -y install --setopt=tsflags=nodocs          \
                   gcc-c++                          \
                   git                              \
                   nano                             \
                   nmap-ncat                        \
                   nodejs                           \
                   rh-postgresql95-postgresql-devel \
                   rh-postgresql95-postgresql-libs  \
                   which                            \
                   &&                               \
    yum clean all

## GIT clone depot.manageiq.org
RUN mkdir -p /opt/depot.manageiq.org && \
    curl -L https://github.com/bdunne/depot.manageiq.org/tarball/openshiftV3 | tar vxz -C /opt/depot.manageiq.org --strip 1

WORKDIR /opt/depot.manageiq.org

RUN . /opt/rh/rh-postgresql95/enable && \
    gem install bundler && \
    bundle install

ADD docker-assets/entrypoint /

ENV APP_ROOT=/opt/depot.manageiq.org
ENV PATH=${APP_ROOT}/bin:${PATH} HOME=${APP_ROOT}
COPY bin/ ${APP_ROOT}/bin/
RUN chmod -R u+x ${APP_ROOT}/bin && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} /etc/passwd

EXPOSE 3000
USER 10001

ENTRYPOINT ["/entrypoint"]
