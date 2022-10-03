# Demo project for Conjur integration with OpenShift/Kubernetes

A demo application creating using the Spring Framework. 
This application requires access to an H2 database.

  * [Pre-requisites](#pre-requisites)
  * [Kubernetes / OCP Setup](#kubernetes---ocp-setup)
    + [Set up a Kubernetes Authenticator endpoint in Conjur / Enable the seed generation  / Initialize the CA (Conjur admin)](#set-up-a-kubernetes-authenticator-endpoint-in-conjur---enable-the-seed-generation----initialize-the-ca--conjur-admin-)
    + [Create Kubernetes resources for the k8s Authenticator (Kubernetes admin)](#create-kubernetes-resources-for-the-k8s-authenticator--kubernetes-admin-)
    + [Configure Conjur to access the Kubernetes API (Conjur admin and Kubernetes cluster admin)](#configure-conjur-to-access-the-kubernetes-api--conjur-admin-and-kubernetes-cluster-admin-)
  * [Conjur follower Deployment (optional)](#conjur-follower-deployment--optional-)
    + [Define an identity in Conjur for the Kubernetes Follower (Conjur admin)](#define-an-identity-in-conjur-for-the-kubernetes-follower--conjur-admin-)
    + [Deploy the follower (Kubernetes admin)](#deploy-the-follower--kubernetes-admin-)
  * [Configure and deploy the sample applications](#configure-and-deploy-the-sample-applications)
    + [Configure the applications](#configure-the-applications)
      - [Load application policies to Conjur (Conjur admin)](#load-application-policies-to-conjur--conjur-admin-)
      - [Create Kubernetes resources for the Applications (Kubernetes admin)](#create-kubernetes-resources-for-the-applications--kubernetes-admin-)
    + [Deploy your application to k8s/Openshift (Application Owner)](#deploy-your-application-to-k8s-openshift--application-owner-)
      - [Option 0 - K8s/Openshift secrets](#option-0---k8s-openshift-secrets)
      - [Option 1 - Secrets Provider for Kubernetes As Init Container](#option-1---secrets-provider-for-kubernetes-as-init-container)
      - [Option 2 - Secrets Provider for Kubernetes As Sidecar Container](#option-2---secrets-provider-for-kubernetes-as-sidecar-container)
      - [Option 3 - Summon as Init Container](#option-3---summon-as-init-container)
      - [Option 4 - Summon as Sidecar Container](#option-4---summon-as-sidecar-container)
      - [Option 5 - Secretless Broker](#option-5---secretless-broker)
      - [Option 6 - Spring Boot](#option-6---spring-boot)
      

## Pre-requisites
- OS Linux / MacOS
- kubectl / oc
- conjur-cli
- envsubst / openssl
- Clone this git repository

## Kubernetes / OCP Setup
```shell
cd setup/k8s
```

###  Set up a Kubernetes Authenticator endpoint in Conjur / Enable the seed generation  / Initialize the CA (Conjur admin)
```shell
./1-load-k8s-authenticator-policies.sh
```
### Create Kubernetes resources for the k8s Authenticator (Kubernetes admin)
```shell
./2-create-k8s-authenticator-resources.sh
```

###  Get Kubernetes API Access Information
```shell
./3-get-k8s-infos.sh
```

###  Configure Conjur to access the Kubernetes API (Conjur admin and Kubernetes cluster admin)
```shell
./4-configure-conjur-for-k8s.sh
```

## Conjur follower Deployment (optional)
### Define an identity in Conjur for the Kubernetes Follower (Conjur admin)
```shell
./5-load-follower-policies.sh
```

### Deploy the follower (Kubernetes admin)
```shell
./6-deploy-follower.sh
```
Check Kubernetes Follower has the status, Ready.

## Configure and deploy the sample applications

###  Configure the applications

Note: All the docker images are already available in dockerhub repository:
- [`docker.io/bnasslahsen/conjur-k8s-demo`](https://hub.docker.com/r/bnasslahsen/conjur-k8s-demo/tags)
- [`docker.io/bnasslahsen/conjur-summon-k8s-demo`](https://hub.docker.com/r/bnasslahsen/conjur-summon-k8s-demo/tags)
- [`docker.io/bnasslahsen/conjur-secretless-k8s-demo`](https://hub.docker.com/r/bnasslahsen/conjur-secretless-k8s-demo/tags)
- [`docker.io/bnasslahsen/conjur-springboot-k8s-demo`](https://hub.docker.com/r/bnasslahsen/conjur-springboot-k8s-demo/tags)
- [`docker.io/bnasslahsen/conjur-k8s-mongodb`](https://hub.docker.com/r/bnasslahsen/conjur-k8s-mongodb/tags)
- [`docker.io/bnasslahsen/conjur-k8s-mongodb-summon-demo`](https://hub.docker.com/r/bnasslahsen/conjur-k8s-mongodb-summon-demo/tags)

```shell
cd setup/demo-apps
```
####  Load application policies to Conjur (Conjur admin)
```shell
./1-load-apps-policies.sh
```
#### Create Kubernetes resources for the Applications (Kubernetes admin)
```shell
./2-configure-apps.sh
```

### Deploy your application to k8s/Openshift (Application Owner)
Once you have a Conjur cluster up and running, policies configured and the initial setup of your k8s/Openshift cluster is done, then:
Edit the `.env` file and set the values depending on your target environment.
After that, choose the option you would like to test and run the related commands.

#### Option 0 - K8s/Openshift secrets
```shell
cd demo-apps/use-cases/basic-k8s-secrets
./deploy-app.sh
```

#### Option 1 - Secrets Provider for Kubernetes As Init Container
```shell
cd demo-apps/use-cases/secrets-provider-for-k8s-init
./deploy-app.sh
```

#### Option 2 - Secrets Provider for Kubernetes As Sidecar Container
```shell
cd demo-apps/use-cases/secrets-provider-for-k8s-sidecar
./deploy-app.sh
```
#### Option 3 - Summon as Init Container
```shell
cd demo-apps/use-cases/summon-init
./deploy-app.sh
```

#### Option 4 - Summon as Sidecar Container
```shell
cd demo-apps/use-cases/summon-sidecar
./deploy-app.sh
```

#### Option 5 - Secretless Broker
```shell
cd demo-apps/use-cases/secretless
./deploy-app.sh
```

#### Option 6 - Spring Boot
```shell
cd demo-apps/use-cases/springboot
./deploy-app.sh
```

#### Option 7 - MongoDB Samples
```shell
cd demo-apps/use-cases/k8s-mongodb-secrets
./deploy-db.sh
./deploy-app-basic.sh
./deploy-app-summon.sh
./deploy-app-push-to-file.sh
```

### Testing the applications
The demo application mocks a pet store service which controls an inventory of pets in a persistent database. The following routes are exposed:

---
`GET` `/pets`  
List all pets in inventory
##### Returns
`200`  
An array of pets in the response body
```
[
  {
    "name": "Scooter"
  },
  {
    "name": "Sparky"
  }
]
```

---
`POST` `/pet`  
Add a pet to the inventory
##### Request
###### Headers
`Content-Type: application/json`
###### Body
```
{
  "name": "Scooter"
}
```
##### Returns
`201`

---
`GET` `/pet/{id}`  
Retrieve information on a pet
##### Returns
`404`
`200`
```
{
  "id": 1
  "name": "Scooter"
}
```
---
`DELETE` `/pet/{id}`  
Remove a pet from inventory
##### Returns
`404`
`200`

---
`GET` `/vulnerable`
Return a JSON representation of all environment variables that
the app knows about
##### Returns
`200`

# License
The Pet Store demo app is licensed under Apache License 2.0 - see [`LICENSE.md`](LICENSE.md) for more details.
