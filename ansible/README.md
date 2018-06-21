# Ansible roles

This directory provides the following roles:

 * coscale-onprem-rhel7
 * coscale-agent-docker
 * coscale-agent-kube
 * coscale-agent-openshift
 * azure-partition-disk


## coscale-onprem-rehl7

This role installs CoScale on-premise on a RHEL7 node. It performs the following tasks:
* installs git and docker,
* checks out the coscale repo in */opt/coscale/cop*,
* create a firewall rule to let the containers connect to the host,
* creates a single-shot systemd service to start CoScale.

**Note: when the role is executed a second time, the CoScale containers will be restarted.**

## coscale-agent-docker

This role peforms the following tasks:
* creates an new application on CoScale,
* creates a Docker agent within that application,
* installs the docker agent.

The role can only be executed on a node that has Docker already installed.

**Caveat: every time the role is executed, a new application is created on CoScale.**

## coscale-agent-kube

This role peforms the following tasks:
* creates an new application on CoScale,
* creates a Kubernetes agent within that application,
* installs the Kubernetes agent by applying a DaemonSet using *kubectl*.

The role can only be executed on a node that has kubectl access to the Kubernetes cluster you whish to monitor.

**Caveat: every time the role is executed, a new application is created on CoScale.**

## coscale-agent-openshift

This role peforms the following tasks:
* creates an new application on CoScale,
* creates a OpenShift agent within that application,
* installs the OpenShift agent by applying a DaemonSet using *oadm* and *oc*.

The role can only be executed on a node that has oc and oadm access to the OpenShift cluster you whish to monitor.

**Caveat: every time the role is executed, a new application is created on CoScale.**

## azure-partition-disk

This role can be used to partition the extra disk on LUN-0 for an Azure VM. */dev/sdc* will be partition and mounted on */opt/coscale/*.

# Examples

The example below can be used to install CoScale on a **RHEL7 Azure VM with an extra disk on LUN-0**. The following steps are executed
* The extra disk is partitioned
* CoScale on-prem is installed
* A CoScale Docker agent is installed to self-monitor the node

```
- hosts: coscale
  become: yes

  vars:
    coscale:
      version: "3.16.0"
      registry_username: "<CoScale registry username>"
      registry_password: "<CoScale registry password>"
      super_user: "<CoScale on-prem superuser email>"
      super_passwd: "<CoScale on-prem superuser password>"
      host: "<CoScale on-prem hostname>"
      mail_server: "<Email server hostname>"
      mail_port: "<Email server port>"
      mail_ssl: "false"
      mail_tls: "false"
      mail_auth: "false"
      mail_username: ""
      mail_password: ""
      from_email: "<From email address>"
      support_email: "<Support email address>"
      anomaly_email: "<Anomaly email address>"
      app_name: "<Application name for self-monitoring>"

  roles:
    - azure-partition-disk
    - coscale-onprem-rhel7
    - coscale-agent-docker
```

The second example creates an new application in CoScale with an OpenShift agent and install the agent on the OpenShift cluster.

```
- hosts: openshift-masters[0]

  vars:
    coscale:
      super_user: "<CoScale on-prem superuser email>"
      super_passwd: "<CoScale on-prem superuser password>"
      host: "<CoScale on-prem hostname>"
      app_name: "<Name for the application>"

  roles:
    - coscale-agent-openshift
```

