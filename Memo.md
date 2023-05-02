# MAIN KUBERNETES COMPONENTS

## Pod

- Pod: It is the smallest unit in K8s.

- It is an abstraction over container. It creates a running environment or a layer on top of the container. 

- It abstract the container so that we can replace them if we want to, and we do not want to work directly with docker or other container technology.

You only interact with the kubernetes Layer.

- Pod is meant to run one application container inside of it. Only in special case you have main service and helper services have to run inside the same "Pod".

- Each Pod gets Its own IP Adrress [`Internal IP`].
- Pods can communicate each other using their `Internal IP Adresses`. However Pods components in Kubernetes are `Ephemeral`! (`They can die very easily from many reasons`).

- In this case, a new Pod will be re-created and assigned  a new IP address. This brings difficulties to maintain communication among pods, when a pod restarts. It is not reliable.

This is where anonther component comes into rescue! that component is `Service`.

---

## Service and Ingress

### Service

- Service is a `Static` or `permanent IP address` that can be attached to each Pod.

 >**Note**: A Service is also a `Loadbalancer`. This means that it catches the requests and forward it to the least busy pod.

- Eg: `my-app` and `my-database`pods, each will have its own service.

- `Good News Here!`. Lifecycle of Pod and Service are not connected! Even if the Pod dies, the Service and its IP will stay. You do not have to change that endpoint anymore!

- Pods now are able to Communicate each other through `Service`.


### Ingress

Now, we want our App to be accessible through a Browser!

- `Remember`, `we wouldn't want our Database to be open to the public requests`. That's dangerous! Instead, we create an `Internal Service` and specify it, when creating database.

Eg: ```http://db-service-ip:port```.


- We can create an `external service`: External services are services that open the communication from external sources.

Eg: ```http://myapp-service-ip:port```.

    - External service is not very practical.
    - Basically what we have above is the htt://Node-IP:port_number-of-the-Service. [ Eg: http://124.89.113.2:8000 ]
    - Not the ServiceIP.

- This method is only good when we want to test something very fast, but not for the Final Product.

- Instead, we want our app to be accessed with a `Secure Protocol` with a `Domain Name`.
    
    Eg: https://my-app.rw

- This is where onother service called `Ingress` comes into rescue!
- The ```Request goes first to Ingress``` and ```ingress does the forwarding```, then to the Service.

---

## ConfigMap and Secret

Usually Pods communicate each other using a Service.
Eg. `my-app` and `Database`. th database will have and endpoint used to communicate with it. eg: ```mongo-db-service```.

- But where do we configure this url or endpoint? usually you will configure into environmental variable of `my-app`. Database URL usually in the `built` application.

- When the URL of Database changes, eg: from ```mongo-db-service``` to ```mongo-db```, we will have to adjust it in our application that is ```my-app```.

- We will have to `Re-build ` our new image, `->` `push into Image repository` `->` and `pull it into our pod`. and then restart the whole thing.

- `Good News here!`. This is where a Kubernetes component called ConfigMap comes into rescue!

### ConfigMap

It is basically our `external configurations` to our Application. It will usually contain data like ```URL``` of database for our app or some other services that we use.

In Kubernetes wi just connect it [ConfigMap] to the Pod, so that the Pod gets the data that the ConfigMap contains.

- Now, If we change the DB_URL, we just adjust the ConfigMap. we do not need to rebuild and go through the whole cycle.

- Part of the External configurtions can be Database ```Username``` and ```password``` , which may also change in the application deployment Process. But:

>**Warning** : `Don't put` Credentials into ConfigMap. especially in plain text. `it is insecure` even though they are part of external configuration.

- For this purpose, kubernetes has another component called `Secret`.

### Secret

Secret Is like ConfigMap, the only difference is that `it is used to store secret data`, Like credetials, Certificates and other things you do not want other people to have access to. And it is not stored in plain text format of course!. but in `base64 encoded ` format.
    
    Eg: DB_USER = username
        DB_PASSWORD = pwd

- The Built-in Security mechanism in kubernetes is not enabled by default.

>**Note** : You can use the Secret component as environmrnt variable or as a Properties file.

---

## Volumes

### Data Storage

Let's say our `database` Pod our application uses, has or generates some data. `If the Database Container or the pod get restarted`, ```the Data is gone!```. That is problematic and inconvenient, obviously because you want you data or logs to be persisted reliably long term. The way you can do it in Kubernetes is using another component called `Volumes`.


How It works, `it basically attaches a physical storage on a hard drive to your pod`.

That Storage could be on a ```local``` machine [`On same server Node Where the Pod is running`], or could be on `remote` storage [`Outside the K8s cluster`] it means that it Could be ``Cloud Storage`` or your ``On-Premises Storage`` which is not part of the K8s Cluster. You just have an external reference on it.

- Now, when our Database container or Pod get restarted, all the Data will be there, persisted.

>**Note** : 
    Think the Storage as an external hard drive plugged in into a kubernetes Cluster. Because K8s Cluster does not explicitily manage Data persistance.

- It means that, you as a user or administarator ```you are responsible``` for `backing up the data`, `replicating` and managing it and making sure it is kept on proper hardware etc.

---
## Deployment and Stateful Set

Let's say our application pod dies, crashes and the user is no longer accessing our app through browser. Here is a downtime.

But in Distributed systems, we do not rely on one application pod. `We Replicate everything`.

This means that we have another `Node` where a `replica` or `clone` of our app would run, and will also be ```connected to the same service```.

Remember that, a `Service` is also a `Loadbalancer`. This means that it catches the requests and forward t it to the least busy pod.

In order to create a second replica of my-app Pod, you wouldn't create a second pod. But instead you would define `blueprints for pods`, and ```specify how many replicas of that Pod``` you would like to run.

And that component of K8s or the Blueprints is called `Deployment`. 

### Deployment

>**Note** : 
    In practice you will not be working with or creating pods. `You will be creating Deployments`, because there you can specify how many replicas, you can also `scale up` or `down` the number of replicas of pods that you need.

- Deployment `is another layer of abstraction of Pods`, which makes it more convenient to interact with pods, replicate them, and do some other configuration.

- In Practice, you will mostly work with Deployment not with Pods.

- Now, If one of replicas of your application will die, the `service will forward the requests to onother one`. The application will still be accessible from the user.

>**Warning**:
 `We can't replicate Database using a Deployment`! and the reason for that is that, ```Database has a State```, which is it's `data`.

 Meaning that, If we have replicas or clones of the database, they would all need to access shared data storage, and there ```you would need some kind of mechanism that manages``` which Pods are currently `writting` to that storage, or which Pods are `reading` to that storage, to `Avoid Data Inconsistences`.

- And that Mechanism in addition to the replicating feature, is offered by another K8s component called `StatefulSet`.

- This component is `meant for applications like Databases`(STATEFUL apps), like MongoDB, MySQL, Elastic Search, Prostgresql and more

>**Note** :
A `Deployment` is used for ```stateLESS``` Apps.
And a`StatefulSet` is used for ```stateFUL``` Apps or Databases.

- StatefulSet will take care of replicating the Pods, scaling them up or down, `but making sure that the Database reads and writes are Synchronized`, so that no database inconsistencies are offered.

>**Warning**: Deploying Databases using StatefulSet in K8s Cluster, can be some what tidious (`Not an easy task`) and `can be more dificult than working with Deployment`.

- That is why it is also a `common practice to host a Database outside a K8s cluster`, and just having Stateless applications in K8s Cluster that replicates and scales with no problem inside K8s Cluster and communicate with and External Database.

---

# KUBERNETES ARCHITECTURE

## Worker Node & Master Node 

We are going to explain how kubernetes does what it does, `how` K8s Cluster is `Self-managed`, `self-healing`, and `Automated` and How you as Operator of the kubernetes cluster, should endup having much `less manual effort`.

### Worker Machine (Node) in K8s Cluster

#### Node processes

 Let's assume a basic setup of one Node with 2 applications pods running on it. One of the main components of the K8s's achitecture, are its `Worker Servers` or `Nodes`.

 - And `each Node will have multiple application Pods with containers` running on that Node.

 - And `the way K8s does it`, is using ```3 processes that must be installed on every Node``` that are used to schedule and manage those pods.

 - So, `Nodes` are `Cluster Servers` that actually do the work. That is why some times they are called `Worker Nodes`.

 #### 1. Container Runtime

 - The `1st process` that need to run on every node, is the `Container Runtime`. Like Docker, but it could be other container technology as well.

 - So, because applications `Pods have containers running inside`, the `Container Runtime` needs to be installed on every node. 
 
 #### 2. Kubelet

 - But, the process (```2nd process```) that actually schedules those pods and the containers in underneath is `Kubelet`. Which is a process of Kubernetes itself unlike Container runtime that has interface with both container runtime and the machine (```The Node itself```), Because at the end of the day Kubelet is responsible for taking that configuration and actually running or starting a Pod with a container inside, and then assigning resources fromthe Node to the container like CPU RAM and storage resources.

 >**Note** : Kubelet ```interacts with both``` the container and Node. And Kubelet `starts the Pod` with a container inside.


 - So, usually kubernetes `Cluster is made up of multiple Nodes`, which also must have container runtime and kubelet services installed. And you can have hundreds of those `Worker Nodes` which will run other Pods and containers and replicas of the existing pods like my-app and database pods in this example.

 - And the way `communication between them` works , is using `Services`, which is a sort of a load balancer that basically catches the request, direct it to the Pod of the application, like Database for example and then forwards it to the respective Pod.

#### 3. Kube Proxy

- And the `3rd Process` that is responsible for ```forwarding requests from Services to Pods```, is actually `Kube Proxy`. And also must be installed on every Node. Kube-Proxy has an intelligent forwarding logic inside tha makes sure that the communication also works in a performant way with low overhead.

    Eg: Even application `my-app` replica is making requests to `Database`, instead of just randomly forwarding requests to any replica, `It will actually forward it to the replica that is running to the same node as the Pod that initiated the request`, thus this way avoiding the network overhead of sending the request to another machine.

>**Note**: Kube-Proxy `forwards` requests.

>**To Summarize**: 3 Node Processes must be installed on every K8s Worker Node.

1. Kubelet
2. Kube Proxy
3. Container runtime (independent)

#### So, Now The Question is: 

##### How Do you Interact with this Cluster?

##### How to:

    1. 'Schedule' Pod?
    2. 'Monitor' pods and when a pod dies it
    3. re-schedule/re-start a pod?
    4. When we add a new Node (Worker Server),
     How does it Join the Cluster to become another Node and gets pods and other components created in it?

**The Answer is**: All these Managing processes are done by `Master Nodes`.


### Master Node

#### Master Processes

So Master Servers (Nodes) have completely different processes running inside. And these are 4 Processes that run on every Master Node that `control the Cluster state` and the `Worker Nodes` as well.

#### 1. API Server

- The `1st` Service is the `API Server`. So When you as a user want to deploy a new application in the K8s Cluster, you interact with the API Server using some Client. It could be UI of K8s Dashboard, CLI tool like kubelet or a Kubernetes API.

>**Note**: `API Server` is like a *`Cluster Gateway`*, Which gets the initial request of any update into the cluster or even the queries from the Cluster. It also act as a *`Gate Keeper`* for the Authentication,to make sure that only the authenticated and authorized requests get through the Cluster.

- That Means that whenever you want to schedule new Pods, deploy new application, Create new service, you have to `talk to` the ```API Server``` on a Master Node.The API Server `validate your request` and everying is fine, then it forwards your request to other processes in order to schedule the Pod or create other component you requested.

- Also if you want to `Query` status of your deployment, Cluster health, etc.., you make the request to the API Server and it gives you the response.

- Which `is good for security`, because `you have only one entrypoint` into the cluster.

- Another Master Process is `Scheduler`.

#### 2. Scheduler
 As Mentioned above, if you send an API Server a request to schedule a new Pod, `API Server after it validates your request`, `it will actually hand it over to the Scheduler` in order to start a new application Pod on one of the Worker Nodes.

 - And of course instead of randomly assigning to any Node, Scheduler has this whole intelligent on deciding on which specific Worker Node the next Node will be scheduled.

 - So, first it will look at your request and see, how much resources the application you want to schedule will need, how much CPU , how much RAM, and then it's gonna go through the Worker Node and se the available resources on each one of them.

 - And if it sees that `one Node is least busy` and `has most resources available`, It will schedule a new pod on that Node.

 >**Note**: Scheduler `just decides` on which Node a new Pod should be scheduled. The process that actually does scheduling, that actually starts that Pod with a container, is the `Kubelet`. Kubelet gets the request from the Scheduler and executes the request on that Node.

 - Another crutial component is the `Controller Manager`.

 #### 3. Controller Manager

 What happens when a pods die on any Node. There must be a way to detect that a Pod died and then reschedule those Pods as soon as possible.

 - So, What `Controller Manager` does is to `detect Cluster state changes` like crashing of Pods for example. When the pod dies, the controller manager detects that, and try to recover the Cluster state as soon as possible.

 - And for that it makes a request to the `Scheduler` to reschedule that died Pods, and the same cycle happens here when the scheduler decides based on the resource calculation, which `Worker Node` should we start these Pods again and makes the request to the corresponding `Kubelet` on these Worker Nodes to actually restart the Pods.

 - And, finally the last master process is `etcd`.

 #### 4. etcd

 `etcd` is a `key value store` of a cluster state.

 >**Note**: You can think of `etcd` as the `Cluster Brain`!. Which means that every change in the cluster, for example when a new Pod is scheduled, when a pod dies, all of these changes get saved or updated into this Key-Value Store.

 - And The reason why the etcd store is the cluster Brain, is because all these mechanism with Scheduler, Controller Manager, etc.. `works because of the etcd`'s `Data`.
    
    Eg: `How` the Scheduler knows what resources are available on each Worker Node,or `how` does controller manager knows that a cluster state changed in some way, for example pods died or that kubelet restarted new Pods up the request of the Scheduler? 

    Or when you make a query request to the API Server about the cluster health,or for example your application deployment state. `where does API Server get all these state information from?`

    So, all these information is stored in etcd cluster. ```What is not stored in etcd``` key value store, `is the actual application data`. For example if you have a database application running inside of a cluster, `the data will be stored somewhere else`, not in the etcd.

    `etcd` is just a `Cluster State Information` which is used for master processes to communicate with the Worker processes and vice-versa.