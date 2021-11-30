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