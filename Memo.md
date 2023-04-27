## Pod

Pod: It is the smallest unity in K8s.
===
- It is an abstraction over container. It creates a running environment or a layer on top of the container. 

- It abstract the container so that we can replace them if we want to, and we do not want to work directly with docker or other container technology.

You only interact with the kubernetes Layer.

- Pod is meant to run one application container inside of it. Only in special case you have main service and helper services have to run inside the same "Pod".

- Each Pod gets Its own IP Adrress [`Internal IP`].
- Pods can communicate each other using their `Internal IP Adresses`. However Pods components in Kubernetes are `Ephemeral`! (`They can die very easily form may reasons`).

- In this case, a new Pod will be re-created and assigned  a new IP address. This brings difficulties to maintain communication among pods, when a pod restarts. It is not reliable.

This is where anonther component comes into rescue! that component is `Service`.

## Service and Ingress

- Service is a `Static` or `permanent IP address` that can be attached to each Pod.

- Eg: `MyApp` and `MyDatabase`pods, each will have its own service.

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

- Instead, we want our app to be accessed with a `Secure Protocol` with a `Domain name`.
    
    Eg: https://my-app.rw

- This is where onother service called `Ingress` comes into rescue!
- The ```Request goes first to Ingress``` and ```ingress does the forwarding```, then to the Service.