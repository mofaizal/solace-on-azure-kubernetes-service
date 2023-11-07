# Setup, Install, Configure and Running webMethods Microservices Runtime on Azure Kubernetes Service

In this article, we will go through the steps required to  Setup, Install, Configure and run webMethods Microservices Runtime on Azure Kubernetes Service.

## Setup 
Provision Azure Kubernetes Service

### Step # 1
Setup subscription context 

```
az account set --subscription <Your Subscription ID>
az account show 

```
Download AKS credentials to configure WebMethodes

```

az aks get-credentials --resource-group <Resource Group Name> --name <AKS Cluster Name>
az aks get-credentials --resource-group <Resource Group Name>-- admin --name <AKS Cluster Name>

```

### Step 2

Setup WebMethodes using YAML

cd / wm-msr-setup

Create namespace “wm-msr” for this sample application. (In general, we are NOT required to create new Namespace)

Execute the following command

```
kubectl create -f sag_wm_msr_namespace.yaml

```
Create Deployment
Configuration defined in Deployment allows running our containerized application in Kubernetes cluster.

```
kubectl create -f sag_wm_msr_dep.yaml

```
Create Service
Configurations defined in Service allow accessing our application to the outside world. As pods in Kubernetes cluster can be added or removed at any time, Services in Kubernetes provides an abstraction to access the underlying application. 


```
kubectl create -f sag_wm_msr_svc.yaml

```

### Launch Admin UI for webMethods Microservices Runtime

```
kubectl port-forward service/wm-msr-svc -n wm-msr 5555
 
```

Login Admin ID : Administrator
default PWD : manage 



To find out the current Azure Kubernetes Service (AKS) context and to switch to another AKS cluster context using kubectl, you can use the following commands. First, you'll need to ensure you have the Azure CLI and kubectl installed and configured.

To find out the current AKS context:

kubectl config current-context

To switch to another AKS cluster context, you can use the kubectl config use-context command with the context name of the AKS cluster you want to switch to.
To list the available contexts, you can use:

kubectl config get-contexts


This will display a list of AKS cluster contexts. Identify the context name you want to switch to.

Then, use the kubectl config use-context command:

kubectl config use-context <context-name>
