# Setup, Install, Configure and Running Solace PubSub+ Software Event Broker on Azure Kubernetes Service

In this article, we will go through the steps required to  Setup, Install, Configure and run Solace PubSub+ Software Event Broker on Azure Kubernetes Service.

## Setup 
Provision Azure Kubernetes Service using terraform script

To deploy HA cluster add this on main.tf
```
locals {
  nodes = {
    for i in range(1, 4) : "worker${i}" => {
      name = i == 1 ? "primary" : i == 2 ? "backup" : i == 3 ? "monitor" : "default"
      vm_size        = "Standard_E4s_v3" //Standard_D2s_v3
      node_count     = 2
      vnet_subnet_id = azurerm_subnet.test.id
      zones          = i == 0 ? ["1"] : i == 1 ? ["2"] : i == 2 ? ["3"] : ["1"]
    }
  }

}

agents_availability_zones = ["1", "2", "3"]

```

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

Check your platform running the `kubectl get nodes` command from your command-line client.

#### Install and setup the Helm package manager

Check to ensure your Kubernetes environment is ready:
```bash
# This shall return worker nodes listed and ready
kubectl get nodes
```

### 2. Install and configure Helm

Follow the [Helm Installation notes of your target release](https://github.com/helm/helm/releases) for your platform.
Note: Helm v2 is no longer supported. For Helm v2 support refer to [earlier versions of the chart](https://github.com/SolaceProducts/pubsubplus-kubernetes-helm-quickstart/releases).

On Linux a simple option to set up the latest stable release is to run:

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Helm is configured properly if the command `helm version` returns no error.


### 3. Install the Solace PubSub+ Software Event Broker with default configuration

- Add the Solace Helm charts to your local Helm repo:
```bash
  helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-helm-quickstart/helm-charts
```
- By default the publicly available [latest Docker image of PubSub+ Software Event Broker Standard Edition](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/) will be used. Specify a different image or [use a Docker image from a private registry](/docs/PubSubPlusK8SDeployment.md#using-private-registries) if required. If using a non-default image, add the `--set image.repository=<your-image-location>,image.tag=<your-image-tag>` values to the commands below.
- Generally, for configuration options and ways to override default configuration values (using `--set` is one the options), consult the [PubSub+ Software Event Broker Helm Chart Reference](/pubsubplus/README.md#configuration).
- Use one of the following chart variants to create a deployment: 

a) Create a Solace PubSub+ Software Event Broker deployment for development purposes using `pubsubplus-dev`. It requires a minimum of 1 CPU and 2 GB of memory available to the event broker pod.
```bash
# Deploy PubSub+ Software Event Broker Standard edition for developers
helm install my-release solacecharts/pubsubplus-dev
```

b) Create a Solace PubSub+ standalone deployment, supporting 100 connections scaling using `pubsubplus`. A minimum of 2 CPUs and 4 GB of memory must be available to the event broker pod.
```bash
# Deploy PubSub+ Software Event Broker Standard edition, standalone
helm install my-release solacecharts/pubsubplus
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 4 GB of memory available to each of the three event broker pods.
```bash
# Deploy PubSub+ Software Event Broker Standard edition, HA
helm install my-release solacecharts/pubsubplus-ha
```

The above options will start the deployment and write related information and notes to the screen.

== Check Solace PubSub+ deployment progress ==
Deployment is complete when a PubSub+ pod representing an active event broker node's label reports "active=true".
Watch progress by running:
   kubectl get pods --namespace default --show-labels -w | grep my-release-pubsubplus-ha

For troubleshooting, refer to ***TroubleShooting.md***

== TLS support ==
TLS has not been enabled for this deployment.

== Admin credentials and access ==
*********************************************************************
* An admin password was not specified and has been auto-generated.
* You must retrieve it and provide it as value override
* if using Helm upgrade otherwise your cluster will become unusable.
*********************************************************************
    Username       : admin
    Admin password : echo `kubectl get secret --namespace default my-release-pubsubplus-ha-secrets -o jsonpath="{.data.username_admin_password}" | base64 --decode`

echo `kubectl get secret --namespace default my-release-pubsubplus-dev-secrets -o jsonpath="{.data.username_admin_password}" | base64 --decode`


    Use the "semp" service address to access the management API via browser or a REST tool, see Services access below.

== Image used ==
solace/solace-pubsub-standard:latest

== Storage used ==
Using persistent volumes via dynamic provisioning with the "default" StorageClass, ensure it exists: `kubectl get sc | grep default`

== Performance and resource requirements ==
The requested connection scaling tier for this deployment is: max 100 connections.
Following resources have been requested per PubSub+ pod:
    echo `kubectl get statefulset --namespace default my-release-pubsubplus-ha -o jsonpath="Minimum resources: {.spec.template.spec.containers[0].resources.requests}"`

== Services access ==
To access services from pods within the k8s cluster, use these addresses:

    echo -e "\nProtocol\tAddress\n"`kubectl get svc --namespace default my-release-pubsubplus-ha -o jsonpath="{range .spec.ports[*]}{.name}\tmy-release-pubsubplus-ha.default.svc.cluster.local:{.port}\n"`

To access from outside the k8s cluster, perform the following steps.

Obtain the LoadBalancer IP and the service addresses:
NOTE: At initial deployment it may take a few minutes for the LoadBalancer IP to be available.
      Watch the status with: 'kubectl get svc --namespace default -w my-release-pubsubplus-ha'

    export SERVICE_IP=$(kubectl get svc --namespace default my-release-pubsubplus-ha --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"); echo SERVICE_IP=$SERVICE_IP
    # Ensure valid SERVICE_IP is returned:
    echo -e "\nProtocol\tAddress\n"`kubectl get svc --namespace default my-release-pubsubplus-ha -o jsonpath="{range .spec.ports[*]}{.name}\t$SERVICE_IP:{.port}\n"`

## Validating the Deployment

Now you can validate your deployment on the command line. In this example an HA configuration is deployed with pod/XXX-XXX-pubsubplus-0 being the active event broker/pod. The notation XXX-XXX is used for the unique release name, e.g: "my-release".

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                                     READY   AGE
statefulset.apps/my-release-pubsubplus   3/3     13m

NAME                                      TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                                                                                                                                   AGE
service/kubernetes                        ClusterIP      10.92.0.1     <none>        443/TCP                                                                                                                                                                   14d
service/my-release-pubsubplus             LoadBalancer   10.92.13.40   34.67.66.30   2222:30197/TCP,8080:30343/TCP,1943:32551/TCP,55555:30826/TCP,55003:30770/TCP,55443:32583/TCP,8008:32689/TCP,1443:32460/TCP,5672:31960/TCP,1883:32112/TCP,9000:30848/TCP   13m
service/my-release-pubsubplus-discovery   ClusterIP      None          <none>        8080/TCP,8741/TCP,8300/TCP,8301/TCP,8302/TCP                                                                                                                              13m

NAME                          READY   STATUS    RESTARTS   AGE
pod/my-release-pubsubplus-0   1/1     Running   0          13m
pod/my-release-pubsubplus-1   1/1     Running   0          13m
pod/my-release-pubsubplus-2   1/1     Running   0          13m

NAME                                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-my-release-pubsubplus-0   Bound    pvc-6b0cd358-30c4-11ea-9379-42010a8000c7   30Gi       RWO            standard       13m
persistentvolumeclaim/data-my-release-pubsubplus-1   Bound    pvc-6b14bc8a-30c4-11ea-9379-42010a8000c7   30Gi       RWO            standard       13m
persistentvolumeclaim/data-my-release-pubsubplus-2   Bound    pvc-6b24b2aa-30c4-11ea-9379-42010a8000c7   30Gi       RWO            standard       13m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                  STORAGECLASS   REASON   AGE
persistentvolume/pvc-6b0cd358-30c4-11ea-9379-42010a8000c7   30Gi       RWO            Delete           Bound    default/data-my-release-pubsubplus-0   standard                13m
persistentvolume/pvc-6b14bc8a-30c4-11ea-9379-42010a8000c7   30Gi       RWO            Delete           Bound    default/data-my-release-pubsubplus-1   standard                13m
persistentvolume/pvc-6b24b2aa-30c4-11ea-9379-42010a8000c7   30Gi       RWO            Delete           Bound    default/data-my-release-pubsubplus-2   standard                13m


prompt:~$ kubectl describe service my-release-pubsubplus
Name:                     my-release-pubsubplus
Namespace:                test
Labels:                   app.kubernetes.io/instance=my-release
                          app.kubernetes.io/managed-by=Tiller
                          app.kubernetes.io/name=pubsubplus
                          helm.sh/chart=pubsubplus-1.0.0
Annotations:              <none>
Selector:                 active=true,app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus
Type:                     LoadBalancer
IP:                       10.100.200.41
LoadBalancer Ingress:     34.67.66.30
Port:                     ssh  2222/TCP
TargetPort:               2222/TCP
NodePort:                 ssh  30197/TCP
Endpoints:                10.28.1.20:2222
:
:
```

Accessing 

Generally, all services including management and messaging are accessible through a Load Balancer. In the above example `34.67.66.30` is the Load Balancer's external Public IP to use.

> Note: When using MiniKube, there is no integrated Load Balancer. For a workaround, execute `minikube service XXX-XXX-solace` to expose the services. Services will be accessible directly using mapped ports instead of direct port access, for which the mapping can be obtained from `kubectl describe service XXX-XX-solace`.

### Solace Admin Portal

![Solace Admin Portal](/solace/images/solace-admin-ui.png "Solace Admin Portal")

![Solace Admin Portal details](/solace/images/solace-admin-ui-detail.png "Solace Admin Portal details")

![Solace deployment details via kubectl](/solace/images/solace-kubectl.png "[Solace deployment details via kubectl")

Refer to the detailed PubSub+ Kubernetes documentation for:
* [Validating the deployment](//github.com/SolaceProducts/pubsubplus-kubernetes-helm-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#validating-the-deployment); or
* [Troubleshooting](//github.com/SolaceProducts/pubsubplus-kubernetes-helm-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting)
* [Modifying or Upgrading](//github.com/SolaceProducts/pubsubplus-kubernetes-helm-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment)
* [Deleting the deployment](//github.com/SolaceProducts/pubsubplus-kubernetes-helm-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#deleting-a-deployment)
  

To find out the current Azure Kubernetes Service (AKS) context and to switch to another AKS cluster context using kubectl, you can use the following commands. First, you'll need to ensure you have the Azure CLI and kubectl installed and configured.

To find out the current AKS context:

kubectl config current-context

To switch to another AKS cluster context, you can use the kubectl config use-context command with the context name of the AKS cluster you want to switch to.
To list the available contexts, you can use:

kubectl config get-contexts


This will display a list of AKS cluster contexts. Identify the context name you want to switch to.

Then, use the kubectl config use-context command:

kubectl config use-context <context-name>
