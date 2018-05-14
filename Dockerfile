#Unapologetically stolen from https://github.com/geerlingguy/docker-centos7-ansible/blob/master/Dockerfile
FROM centos:7

ENV container=docker

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_SSH_PIPELINING True

# Not sure if needed
#ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
#ENV ANSIBLE_LIBRARY /ansible/library


# Needed because SystemD is evil and horrible and stuff
VOLUME [ "/sys/fs/cgroup", "/tmp", "/run","/run/lock","/ansible" ]
STOPSIGNAL SIGRTMIN+3

# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y update; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install Ansible and other requirements.
RUN yum makecache fast \
 && yum -y install deltarpm epel-release initscripts \
 && yum -y update \
 && yum -y install ansible sudo which  \
 && yum clean all

# Add systemd service for ansible that runs after all of the normal "multi-user.target" services
ADD start-ansible /usr/local/bin
ADD systemd/custom.target /etc/systemd/system/
ADD systemd/ansible.service /etc/systemd/system/custom.target.wants/
RUN ln -sf /etc/systemd/system/custom.target /etc/systemd/system/default.target

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts ;\
    sed -i -e 's/^#log_path.*$/log_path = \/var\/log\/ansible.log/' /etc/ansible/ansible.cfg

ENTRYPOINT ["/sbin/init"]
