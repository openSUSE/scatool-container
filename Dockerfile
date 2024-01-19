# SPDX-License-Identifier: MIT
# Define the tags for OBS and build script builds:
#!BuildTag: %%TAGPREFIX%%/scatool:latest
#!BuildTag: %%TAGPREFIX%%/scatool:%%PKG_VERSION%%
#!BuildTag: %%TAGPREFIX%%/scatool:%%PKG_VERSION%%-%RELEASE%

FROM opensuse/tumbleweed:latest

ARG USERNAME="scawork"
ARG HOMEDIR="/home/$USERNAME"
ARG VOLDIR="/var/scatool"

# Mandatory labels for the build service:
#   https://en.opensuse.org/Building_derived_containers
# labelprefix=%%LABELPREFIX%%
LABEL org.opencontainers.image.title="SCA Tool Container"
LABEL org.opencontainers.image.description="Container for supportconfig analysis with scatool"
LABEL org.opencontainers.image.created="%BUILDTIME%"
LABEL org.opencontainers.image.version="%%PKG_VERSION%%.%RELEASE%"
LABEL org.opencontainers.image.url="https://build.opensuse.org/package/show/SUSE:ALP:Workloads/scatool-container"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL org.opensuse.reference="%%REGISTRY%%/%%TAGPREFIX%%/scatool:%%PKG_VERSION%%.%RELEASE%"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL com.suse.supportlevel="techpreview"
LABEL com.suse.eula="beta"
LABEL com.suse.image-type="application"
LABEL com.suse.release-stage="prototype"
# endlabelprefix

RUN echo "+ Installing the SCA Tool application" && \
zypper --non-interactive install --allow-unsigned-rpm \
bzip2 \
file \
gzip \
sca-patterns-base \
sca-server-report \
sca-patterns-alp1 \
sca-patterns-sle11 \
sca-patterns-sle12 \
sca-patterns-sle15 \
tar \
xz && \
zypper clean --all

RUN echo "+ Creating $USERNAME user" && \
useradd -d $HOMEDIR $USERNAME && \
chown -R $USERNAME:$USERNAME $HOMEDIR

COPY sca-analysis /usr/local/bin
COPY entrypoint.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/sca-analysis
RUN chmod 755 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

USER $USERNAME
