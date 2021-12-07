# Secure Apache Druid on AKS

This is a demo repo to deploy an Apache Druid environment on AKS in secured private virtual network.

To install the full architecture (Azure resources and Druid):

1. Chance the ```run.rc``` file to reflect your environment
2. Run: 
    ```bash
    ./run.sh -x install
    ```

To remove the entire deployment:
1. Run:
    ```bash
    ./run.sh -x delete
    ```

Usage:

```
run.sh [-x actions][-o options]
    -o  options
    -x  action to be executed.
    
Possible verbs are:
    install        deploy resources.
    delete         delete resources.
    dry-run        tries the current Bicep deployment against Azure but doesn't deploy (what-if).
    
Apache Druid:
    install-druid  only installs the Apache Druid on the cluster.
    delete-druid   removes Apache Druid from the cluster.
    
Options:
    KeepSSHKeys    do not remove the SSH keys (used with the -x delete option).
```
