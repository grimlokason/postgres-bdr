FROM debian:stretch

ENV PG_MAJOR=9.4 PG_CLUSTER=bdr

ADD https://www.postgresql.org/media/keys/ACCC4CF8.asc /tmp
ADD https://apt.2ndquadrant.com/site/keys/9904CD4BD6BAF0C3.asc /tmp

RUN apt-get update \
	&& apt-get install -y --no-install-recommends gnupg apt-transport-https ca-certificates \
	&& apt-key add /tmp/ACCC4CF8.asc \
	&& apt-key add /tmp/9904CD4BD6BAF0C3.asc \
	&& rm -f /tmp/*.asc \
	&& echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >/etc/apt/sources.list.d/postgres-pgdg.list \
	&& echo "deb https://apt.2ndquadrant.com/ stretch-2ndquadrant main" >/etc/apt/sources.list.d/postgres-2ndquarant.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends locales postgresql-common \
	&& echo "en_US.UTF-8 UTF-8" >/etc/locale.gen \
	&& locale-gen \
	&& sed -ri "s/#(create_main_cluster).*$/\1 = false/" /etc/postgresql-common/createcluster.conf \
	&& apt-get install -y --no-install-recommends postgresql-bdr-contrib-${PG_MAJOR} postgresql-bdr-${PG_MAJOR} postgresql-bdr-${PG_MAJOR}-bdr-plugin \
	&& apt-get purge -y gnupg apt-transport-https ca-certificates \
	&& apt-get -y --purge autoremove \
	&& rm -rf /var/lib/apt/lists/*

COPY init /sbin/

EXPOSE 5432
LABEL org.discourse.service._postgresql.port=5432

VOLUME /var/lib/postgresql

ENTRYPOINT ["/sbin/init"]
