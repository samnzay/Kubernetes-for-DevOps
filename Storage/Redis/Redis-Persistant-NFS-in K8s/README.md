# Distributed Caching Pattern for Microservices with Redis Kubernetes.

Caching is one of the key implementation when it comes to production level deployment of services, which help us to increase the performance of the system by staying as a middle layer between a particular application and the persistence system where the actual data is kept.

When we go through the possible patterns of caching implementation in a microservice architecture, there are several patterns available including:

    1. Embedded Cache
    2. Embedded Distributed Cache
    3. Client Server Cache
    4. Cloud Cache
    5. Sidecar Cache
    6. Distributed Cache
    7. etc…

To get more understanding on these patterns you can refer [1] and [2] where we can find more detailed explanation .

In this article my intention is to discuss about the Distributed Cache Pattern and how we can deploy a Distributed Cache Solution using Redis in both Single Node and also with High available Setup.

As initial step we will look at about what this Distributed Cache Means — below quote has been extracted from [3].

*A `distributed cache` is a system that pools together the random-access memory (RAM) of multiple networked computers into a single in-memory data store used as a data cache to provide fast access to data.*

Below diagram depicts a typical use case where the distributed cache is used. Same use case we are going to Implement using Spring Boot, MysQL and Redis on top of Kubernetes.

[typical use case where the distributed cach](architecture/distributed_usecase.webp)


## What we are going to do here!

    1. Setting up a Single Node Redis Deployment
    2. Setting up a HA Redis Deployment ( Cluster Disabled and Using 
    3. Sentinel for High Availability )
    4. Prepare a sample Spring Boot Microservice to test the Caching 
    5. Between Application and the MySQL

## Setting up a Single Node Redis Deployment

Below diagram depicts what are components needed and how they interconnected when we are doing a Single Node Redis Deployment in Kubernetes.

[Application Architecture](architecture/app_Architecture.webp)

**Spring Boot Application** — Application created to test the Caching.

**Redis Service** — This is a Kubernetes Service of the Redis, used as the entry point from the Spring Boot Application.

**Redis** — This is the Redis POD which runs as StatefulSet in Kubernetes.

**NFS Storage Provisioner** — This is to provision the Persistence Volumes dynamically through Persistence Volume Claims. This is actually needed when we go with the Redis Cluster, but I have implemented the same with Single Node also as the it can be re-used. Here using the [4] nfs-subdir-external-provisioner, as the default nfs provisioner is no more maintained and also when using the old one facing an issue, its not properly starting the NFS Provisioner POD in Kubernetes ( minikube version: v1.22.0 ).

**External NFS Server** — Used for the Persistence Storage.

**Minikube** — For the local tetsing purpose we can use Minikube for setting up the Kubernetes Cluster.

Note: Here I’m not going to explain about setting up the Minikube, refer [5] if you are getting started on it.


## Step-1: Preparing the Storage Class.

## Step-2: Preparing the Role and Access Control.

## Step-3: Preparing the Deployment File.

[Resource About Redis](https://stackoverflow.com/questions/70620871/redis-pod-with-3-replica-and-persistence-storage-not-providing-data-all-the-time)


Now we are done with the Single Node Setup and we will verify this through Spring Boot Application when we are at the 

**Section: 3.**

## Setting up a HA Redis Deployment

When it comes to high available setup, there are two options one is using the cluster enabled and cluster disabled option. There are pros and cons in these two setup, to get more information refer “comparing cluster options” link.

Here I’m going to setup the Cluster Disabled mode where the High availability is achieved by using Sentinel. Sentinel will monitor the Nodes and for example consider that the master node failed then it will make one of the slave as master to make it available.

In this setup there will 3-Redis Nodes, 3-Sentinel Nodes along with 2-NFS Provisioner to make the high availability.

**Step-1:** Deploy the NFS Provisioner by increasing the replicas to 2.

**Step-2:** Use the same Redis Config file and deploy it.

**Step-3:** Use the same Redis Deployment file and update the replicas to 3 and deploy the file.

**Step-4:** Prepare the Sentinel Deployment File.

>**Note**: Need to update the <namespace> tag accordingly.


**REFERENCE:**
[Redis on Kubernetes for beginners](https://www.youtube.com/watch?v=JmCn7k0PlV4)

[Dynamically provision NFS persistent volumes in Kubernetes](https://www.youtube.com/watch?v=AavnQzWDTEk)

[Medium](https://medium.com/geekculture/distributed-caching-pattern-for-microservices-with-redis-d95ea7c0e8f8)