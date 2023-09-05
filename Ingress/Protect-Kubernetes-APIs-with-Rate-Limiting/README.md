# Protect Kubernetes APIs with Rate Limiting

Your organization just launched its first app and API in Kubernetes. You’ve been told to expect high traffic volumes (and already implemented autoscaling to ensure NGINX Ingress Controller can quickly route the traffic), but there are concerns that the API may be targeted by a malicious attack. If the API receives a high volume of HTTP requests – a possibility with brute‑force password guessing or DDoS attacks – then both the API and app might be overwhelmed or even crash.

But you’re in luck! The traffic‑control technique called rate limiting is an API gateway use case that limits the incoming request rate to a value typical for real users. You configure NGINX Ingress Controller to implement a rate‑limiting policy, which prevents the app and API from getting overwhelmed by too many requests. Nice work!


## Lab and Tutorial Overview
This blog accompanies the lab for Unit 2 of Microservices March 2022 – Exposing APIs in Kubernetes, demonstrating how to combine multiple NGINX Ingress Controllers with rate limiting to prevent apps and APIs from getting overwhelmed.

To run the tutorial, you need a machine with:

- 2 CPUs or more
- 2 GB of free memory
- 20 GB of free disk space
- Internet connection
- Container or virtual machine manager, such as Docker, Hyperkit, Hyper-V, KVM, Parallels, Podman, VirtualBox, or VMware Fusion/Workstation
- minikube installed
- Helm installed
A configuration that allows you to launch a browser window. If that isn’t possible, you need to figure out how to get to the relevant services via a browser.

This tutorial uses these technologies:

- NGINX Ingress Controller (based on NGINX Open Source)
- BusyBox
- Helm
- Locust
- minikube
- Podinfo

This tutorial includes three challenges:

1. Deploy a Cluster, App, API, and Ingress Controller
2. Overwhelm Your App and API
3. Save Your App and API with Dual Ingress Controllers and Rate Limiting

## Challenge 1: Deploy a Cluster, App, API, and Ingress Controller
In this challenge, you deploy a minikube cluster and install Podinfo as a sample app and API. You then deploy NGINX Ingress Controller, configure traffic routing, and test the Ingress configuration.


### Create a Minikube Cluster
Create a minikube cluster. After a few seconds, a message confirms the deployment was successful.
```shell
minikube start 
#🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default 
```

### Install the Podinfo App and Podinfo API
Podinfo is a “web application made with Go that showcases best practices of running microservices in Kubernetes”. We’re using it as a sample app and API because of its small footprint.

1. Using the text editor of your choice, create a YAML file called `1-apps.yaml` with the following contents. It defines a Deployment that includes:

- A web app (we’ll call it Podinfo Frontend) that renders an HTML page
- An API (Podinfo API) that returns a JSON payload

2. Deploy the app and API:
```shell
kubectl apply -f 1-apps.yaml
: '
deployment.apps/api created 
service/api created 
deployment.apps/frontend created 
service/frontend created
'
```

3. Confirm that the pods for Podinfo API and Podinfo Frontend deployed successfully, as indicated by the value Running in the STATUS column.
```shell
kubectl get pods
: ' 
NAME                        READY   STATUS    RESTARTS  AGE 
api-7574cf7568-c6tr6        1/1     Running   0         87s 
frontend-6688d86fc6-78qn7   1/1     Running   0         87s 
'
```
### Deploy NGINX Ingress Controller
The fastest way to install NGINX Ingress Controller is with Helm.

Install NGINX Ingress Controller in a separate namespace (nginx) using Helm.

1. Create the namespace:
```shell
kubectl create namespace nginx
```
2. Add the NGINX repository to Helm:
```shell
helm repo add nginx-stable https://helm.nginx.com/stable
```
3. Download and install NGINX Ingress Controller in your cluster:
```shell
#helm install main nginx-stable/nginx-ingress \ 
#    --set controller.watchIngressWithoutClass=true \ 
#    --set controller.ingressClass=nginx \ 
#    --set controller.service.type=NodePort \ 
#    --set controller.service.httpPort.nodePort=30010 \ 
#    --set controller.enablePreviewPolicies=true \ 
#    --namespace nginx

helm install main nginx-stable/nginx-ingress --set controller.watchIngressWithoutClass=true --set controller.ingressClass=nginx --set controller.service.type=LoadBalancer --set controller.enablePreviewPolicies=true --namespace nginx
```

4. Confirm that the NGINX Ingress Controller pod deployed, as indicated by the value Running in the STATUS column (for legibility, the output is spread across two lines).
```shell
kubectl get pods --namespace nginx 
: '
NAME                                  READY   STATUS   ...
main-nginx-ingress-779b74bb8b-d4qtc   1/1     Running  ...

    ... RESTARTS   AGE 
    ... 0          92s 
'
```

### Route Traffic to Your App
Using the text editor of your choice, create a YAML file called `2-ingress.yaml` with the following contents. It defines the Ingress manifest required to route traffic to the app and API.

1. Deploy the Ingress resource:
```shell
kubectl apply -f 2-ingress.yaml
: '
ingress.networking.k8s.io/first created
'
```
#### Enable Minikube Tunnel
Services of type LoadBalancer can be exposed via the minikube tunnel command. It must be run in a separate terminal window to keep the LoadBalancer running. Ctrl-C in the terminal can be used to terminate the process at which time the network routes will be cleaned up.

The `minikube tunnel` runs as a process, creating a network route on the host to the service CIDR of the cluster using the cluster’s IP address as a gateway. The tunnel command exposes the external IP directly to any program running on the host operating system.

```shell
minikube tunnel
```
#### OR
- Cleaning up orphaned routes then, Run Tunnel
If the minikube tunnel shuts down in an abrupt manner, it may leave orphaned network routes on your system. If this happens, the ~/.minikube/tunnels.json file will contain an entry for that tunnel. To remove orphaned routes, run:

```shell
minikube tunnel --cleanup
```
### Check The ingress IP
After Tunneling in Minikube, Our Loadbalancer type services get External IP, That assigns ADDRESS to our ingress.
```shell
kubectl get ingress
: '
NAME    CLASS   HOSTS                         ADDRESS         PORTS   AGE
first   nginx   example.com,api.example.com   10.99.141.245   80      9m41s
'

```
Note the `ADDRESS` value of Ingress as we are going to use it in Domains configuration in local computer.

### Configures our Apps Domains In Local machine
Open `etc/hosts` and append this Address and domain mapping, so that we can access via browser exertnally.
```shell
sudo nano /etc/hosts
#Append below content and remember to replace IP with yours, and Save
:'
10.99.141.245 example.com,
10.99.141.245 api.example.com
'
```


### Test the Ingress Configuration
1. To ensure your Ingress configuration is performing as expected, test it using a temporary pod. Launch a disposable BusyBox pod in the cluster:
```shell
kubectl run -ti --rm=true busybox --image=busybox
: '
If you don't see a command prompt, try pressing enter.
#
'
```
2. Test `Podinfo API` by issuing a request to the NGINX Ingress Controller pod with the hostname `api.example.com`. The output shown indicates that the API is receiving traffic.

```shell
wget --header="Host: api.example.com" -qO- api.example.com
: '
{ 
  "hostname": "api-687fd448f8-t7hqk", 
  "version": "6.0.3", 
  "revision": "", 
  "color": "#34577c", 
  "logo": "https://raw.githubusercontent.com/stefanprodan/podinfo/gh-pages/cuddle_clap.gif", 
  "message": "greetings from podinfo v6.0.3", 
  "goos": "linux", 
  "goarch": "arm64", 
  "runtime": "go1.16.9", 
  "num_goroutine": "6", 
  "num_cpu": "4" 
}
' 
```

3. Test Podinfo Frontend by issuing the following command in the same BusyBox pod to simulate a web browser and retrieve the web page. The output shown is the HTML code for the start of the web page.

```shell
wget --header="Host: example.com" --header="User-Agent: Mozilla" -qO- example.com
: '
<!DOCTYPE html> 
<html> 
<head> 
  <title>frontend-596d5c9ff4-xkbdc</title> 
  # ...
'
```
4. In another terminal, open Podinfo [`fontend`] in a browser. The greetings from podinfo page indicates Podinfo is running.
```shell
minikube service frontend
```

>**Note**: Congratulations! NGINX Ingress Controller is receiving requests and forwarding them to the app and API.

5. In the original terminal, end the BusyBox session:

```shell
exit
#
```
## Challenge 2: Overwhelm Your App and API
In this challenge, you install Locust, an open source load‑generation tool, and use it to simulate a traffic surge that overwhelms the API and causes the app to crash.

### Install Locust

1. Using the text editor of your choice, create a YAML file called `3-locust.yaml` with the following contents.

The ConfigMap object defines a script called locustfile.py which generates requests to be sent to the pod, complete with the correct headers. The traffic is not distributed evenly between the app and API – requests are skewed to Podinfo API, with only 1 of 5 requests going to Podinfo Frontend.

The Deployment and Service objects define the Locust pod.

3. Deploy Locust:
```shell
kubectl apply -f  3-locust.yaml
: '
configmap/locust-script created 
deployment.apps/locust created 
service/locust created
'
```
3. Verify the Locust deployment. In the following sample output, the verification command was run just a few seconds after the `kubectl apply` command and so the installation is still in progress, as indicated by the value `ContainerCreating` for the Locust pod in the `STATUS` field. Wait until the value is Running before continuing to the next section. (The output is spread across two lines for legibility.)

```shell
kubectl get pods
: '
NAME                        READY   STATUS            ...           api-7574cf7568-c6tr6        1/1     Running           ...
frontend-6688d86fc6-78qn7   1/1     Running           ...            locust-77c699c94d-hc76t     0/1     ContainerCreating ...

      ... RESTARTS   AGE 
      ... 0          33m
      ... 0          33m
      ... 0           4s
'
```
### Simulate a Traffic Surge

1. Open Locust in a browser.
```shell
minikube service locust
```
2. Enter the following values in the fields:

- Number of users – 1000
- Spawn rate – 30
- Host – http://example.com

3. Click the Start swarming button to send traffic to Podinfo API and Podinfo Frontend. Observe the traffic patterns on the Locust - Charts and Failures tabs:

- Chart – As the number of API requests increases, the Podinfo API response times worsen.
- Failures – Because Podinfo API and Podinfo Frontend share an Ingress controller, the increasing number of API requests soon causes the web app to start returning errors.

This is problematic because a single bad actor using the API can take down not only the API, but all apps served by NGINX Ingress Controller!

## Challenge 3: Save Your App and API with Dual Ingress Controllers and Rate Limiting

In the final challenge, you deploy two NGINX Ingress Controllers to eliminate the limitations of the previous deployment, creating a separate namespace for each one, installing separate NGINX Ingress Controller instances for Podinfo Frontend and Podinfo API, reconfigure Locust to direct traffic for the app and API to their respective NGINX Ingress Controllers, and verify that rate limiting is effective.

First, let’s look at how to address the architectural problem. In the previous challenge, you overwhelmed NGINX Ingress Controller with API requests, which also impacted the app. This happened because a single Ingress controller was responsible for routing traffic to both the web app (Podinfo Frontend) and the API (Podinfo API).

![Shared Ingress](/images/shared_ingress.png)

Running a separate NGINX Ingress Controller pod for each of your services prevents your app from being impacted by too many API requests. This isn’t necessarily required for every use case, but in our simulation it’s easy to see the benefits of running multiple NGINX Ingress Controllers.

![Separate Ingress](/images/two_ingress.png)

The second part of the solution, which prevents `Podinfo API` from getting overwhelmed, is to implement rate limiting by using NGINX Ingress Controller as an API gateway.

#### What Is Rate Limiting?
Rate limiting restricts the number of requests a user can make in a given time period. To mitigate a DDoS attack, for example, you can use rate limiting to limit the incoming request rate to a value typical for real users. When rate limiting is implemented with NGINX, clients that submit too many requests are redirected to an error page so they cannot negatively impact the API. Learn how this works in the NGINX Ingress Controller documentation.

#### What Is an API Gateway?
An API gateway routes API requests from clients to the appropriate services. A big misinterpretation of this simple definition is that an API gateway is a unique piece of technology. It’s not. Rather, “API gateway” describes a set of use cases that can be implemented via different types of proxies – most commonly an ADC or load balancer and reverse proxy, and increasingly an Ingress controller or service mesh. Rate limiting is a common use case for deploying an API gateway. Learn more about API gateway use cases in Kubernetes in How Do I Choose? API Gateway vs. Ingress Controller vs. Service Mesh on our blog.


Before you can implement the new architecture and rate limiting, you must delete the previous NGINX Ingress Controller configuration.

1. Delete the NGINX Ingress Controller configuration:
```shell
kubectl delete -f 2-ingress.yaml
: '
ingress.networking.k8s.io "first" deleted
'
```
2. Create a namespace called `nginx‑web` for `Podinfo Frontend`:
```shell
kubectl create namespace nginx-web
: '
namespace/nginx-web created
' 
```
3. Create a namespace called nginx‑api for Podinfo API:
```shell
kubectl create namespace nginx-api
: '
namespace/nginx-api created
'
```

### Install the NGINX Ingress Controller for Podinfo Frontend

1. Install NGINX Ingress Controller:
```shell
: '
helm install web nginx-stable/nginx-ingress  
  --set controller.ingressClass=nginx-web \ 
  --set controller.service.type=NodePort \ 
  --set controller.service.httpPort.nodePort=30020 \ 
  --namespace nginx-web
'

helm install web nginx-stable/nginx-ingress --set controller.ingressClass=nginx-web --set controller.service.type=LoadBalancer --namespace nginx-web
```
2. Create an Ingress manifest called `4-ingress-web.yaml` for `Podinfo Frontend`.

```shell
apiVersion: networking.k8s.io/v1 
kind: Ingress 
metadata: 
  name: frontend
spec: 
  ingressClassName: nginx-web 
  rules: 
    - host: "example.com" 
      http: 
        paths: 
          - backend: 
              service: 
                name: frontend 
                port: 
                  number: 80 
            path: / 
            pathType: Prefix 
```

 3. Deploy the new manifest:

 ```shell
kubectl apply -f 4-ingress-web.yaml
: '
ingress.networking.k8s.io/frontend created
'
 ```
>**Warning**: Ingress resource must be in the same namespace with the apps it is meant to route traffic to. Otherwise you will receive bad gateway.

### Install the NGINX Ingress Controller for Podinfo API
The manifest you created in the last section is exclusively for the NGINX Ingress Controller for `Podinfo Frontend`, as specified by the value nginx‑web in the `ingressClassName` field. Now you install an NGINX Ingress Controller for `Podinfo API`, including a `rate‑limiting policy` to prevent your API from getting overwhelmed.

There are two ways to configure rate limiting with NGINX Ingress Controller:

1. `NGINX Ingress resources` – NGINX Ingress resources are an alternative to Kubernetes custom resources. They provide a native, type‑safe, and indented configuration style which simplifies implementation of Ingress load balancing capabilities, including:

    - `Circuit breaking` – For appropriate handling of application errors
    - `Sophisticated routing` – For A/B testing and blue‑green deployments
    - `Header manipulation` – For offloading application logic to the NGINX Ingress controller
    - `Mutual TLS authentication (mTLS)` – For zero‑trust or identity‑based security
    - `Web application firewall (WAF)` – For protection against HTTP vulnerability attacks.

2. `Snippets` – Snippets are a mechanism for inserting raw NGINX configuration into different contexts of the configurations generated by NGINX Ingress Controller. While snippets are a possible approach, we recommend avoiding them whenever possible because they’re error‑prone, can be difficult to work with, don’t provide fine‑grained control, and can create security issues.

This tutorial uses the NGINX Ingress policy resource called `rateLimit`, which offers numerous configuration options. In this challenge, you use just the three required parameters:

`rate` – The maximum permitted rate of requests, expressed in requests per second (r/s) or requests per minute (r/m).
`key` – The characteristic by which each requester is uniquely identified, for example its IP address. The value can contain text, variables, or a combination.
`zoneSize` – The amount of shared memory allocated for the NGINX worker processes to keep track of requests, expressed in `KB` (K) or `MB` (M).

This example limits each requester to 10 requests per second, identifying requesters by IP address (captured by the NGINX variable `${binary_remote_addr}`), and allocates `10 MB` for the shared memory zone.

```shell
rateLimit: 
      rate: 10r/s 
      key: ${binary_remote_addr}
      zoneSize: 10M 
```

1. Install NGINX Ingress Controller:
```shell
: '
helm install api nginx-stable/nginx-ingress  --set controller.ingressClass=nginx-api --set controller.service.type=NodePort --set controller.service.httpPort.nodePort=30030 --set controller.enablePreviewPolicies=true --namespace nginx-api
'

helm install api nginx-stable/nginx-ingress --set controller.ingressClass=nginx-api --set controller.service.type=LoadBalancer --set controller.enablePreviewPolicies=true --namespace nginx-api
```

2. Create an Ingress manifest called `5-ingress-api.yaml` for `Podinfo API`.
```shell
apiVersion: k8s.nginx.org/v1 
kind: Policy 
metadata: 
  name: rate-limit-policy
spec: 
  rateLimit: 
    rate: 10r/s 
    key: ${binary_remote_addr} 
    zoneSize: 10M 
--- 
apiVersion: k8s.nginx.org/v1 
kind: VirtualServer 
metadata: 
  name: api-vs 
spec: 
  ingressClassName: nginx-api 
  host: api.example.com 
  policies: 
  - name: rate-limit-policy 
  upstreams: 
  - name: api 
    service: api 
    port: 80 
  routes: 
  - path: / 
    action: 
      pass: api 
```

3. Deploy the new manifest:
```shell
kubectl apply -f 5-ingress-api.yaml
: '
ingress.networking.k8s.io/api created
'
```
4. Check the virtualserver (Ingress)
Check the recently deployed VertualServer (Ingress) and Note its IP address. As we will map it into `/etc/hosts` file.
```shell
kubectl get vs -A
: '
NAMESPACE   NAME     STATE   HOST              IP             PORTS      AGE
nginx-api   api-vs   Valid   api.example.com   10.103.118.7   [80,443]   10m
'
```
### Reconfigure Locust
Now, reconfigure Locust and verify that:

- `Podinfo API` doesn’t get overloaded.
- No matter how many requests are sent to `Podinfo API`, there is no impact on `Podinfo Frontend`.

Perform these steps:

1. Change the Locust script so that:

- All requests to Podinfo Frontend are directed to the nginx‑web NGINX Ingress Controller at http://web-nginx-ingress.nginx-web
- All requests to Podinfo API are directed to the nginx‑api NGINX Ingress Controller at http://api-nginx-ingress.nginx-api

Because Locust supports just a single URL in the dashboard, hardcode the value in the Python script using the YAML file `6-locust.yaml` with the following contents. Take note of the URLs in each task.

```shell
apiVersion: v1 
kind: ConfigMap 
metadata: 
  name: locust-script 
data: 
  locustfile.py: |- 
    from locust import HttpUser, task, between 

    class QuickstartUser(HttpUser): 
        wait_time = between(0.7, 1.3) 

        @task(1) 
        def visit_website(self): 
            with self.client.get("http://example.com", headers={"Host": "example.com", "User-Agent": "Mozilla"}, timeout=0.2, catch_response=True) as response: 
                if response.request_meta["response_time"] > 200: 
                    response.failure("Frontend failed") 
                else: 
                    response.success() 
  

        @task(5) 
        def visit_api(self): 
            with self.client.get("http://api.example.com", headers={"Host": "api.example.com"}, timeout=0.2) as response: 
                if response.request_meta["response_time"] > 200: 
                    response.failure("API failed") 
                else: 
                    response.success() 
--- 
apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: locust 
spec: 
  selector: 
    matchLabels: 
      app: locust 
  template: 
    metadata: 
      labels: 
        app: locust 
    spec: 
      containers: 
        - name: locust 
          image: locustio/locust 
          ports: 
            - containerPort: 8089 
          volumeMounts: 
            - mountPath: /home/locust 
              name: locust-script 
      volumes: 
        - name: locust-script 
          configMap: 
            name: locust-script 
--- 
apiVersion: v1 
kind: Service 
metadata: 
  name: locust 
spec: 
  ports: 
    - port: 8089 
      targetPort: 8089 
      nodePort: 30015 
  selector: 
    app: locust 
  type: LoadBalancer
```

2. Deploy the new Locust configuration. The output confirms that the script changed but the other elements remain unchanged.
```shell
kubectl apply -f 6-locust.yaml
: '
configmap/locust-script configured 
deployment.apps/locust unchanged 
service/locust unchanged
'
```
3. Delete the Locust pod to `force a reload of the new ConfigMap`. To identify the pod to remove, the argument to the `kubectl delete pod` command is expressed as piped commands that select the Locust pod from the list of all pods.
```shell
kubectl delete pod `kubectl get pods | grep locust | awk {'print $1'}`
```

4. Verify Locust has been reloaded (the value for the Locust pod in the AGE column is only a few seconds).
```shell
kubectl get pods
: '
NAME                        READY   STATUS   ...           api-7574cf7568-jrlvd        1/1     Running  ...
frontend-6688d86fc6-vd856   1/1     Running  ...            locust-77c699c94d-6chsg     0/1     Running  ...

      ... RESTARTS   AGE 
      ... 0        9m57s
      ... 0        9m57s
      ... 0           6s
'
```

#### Prepare for Stress Testing

1. Remember to Enable Minikube Tunnel
Remember to enable minikube tunnel to access Service externally via NGINX Ingress (`VirtualServer`) this time.
```shell
minikube tunnel
```
Enter you pc admin password when prompted.

2. ##### Check the VirtualServer Ingress IP
List Available Virual Servier in all namespaces. We expect `api-vs` in our case.
```shell
kubectl get vs -A
: '
NAMESPACE   NAME     STATE   HOST              IP             PORTS      AGE
nginx-api   api-vs   Valid   api.example.com   10.103.118.7   [80,443]   10m
'
```
Verify Services
```shell
kubectl get svc -A
: '
NAMESPACE     NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
default       api                             LoadBalancer   10.96.47.193    10.96.47.193    80:30001/TCP                 23h
default       frontend                        LoadBalancer   10.101.129.26   10.101.129.26   80:30002/TCP                 23h
default       kubernetes                      ClusterIP      10.96.0.1       <none>          443/TCP                      2d1h
kube-system   kube-dns                        ClusterIP      10.96.0.10      <none>          53/UDP,53/TCP,9153/TCP       2d1h
nginx-api     api-nginx-ingress-controller    LoadBalancer   10.103.118.7    10.103.118.7    80:32494/TCP,443:30337/TCP   11m
nginx         main-nginx-ingress-controller   LoadBalancer   10.99.141.245   10.99.141.245   80:30956/TCP,443:30213/TCP   23h

'
#The above VirtualServer took its IP from the  Service named "api-nginx-ingress-controller" EXTERNAL-IP. Take a Closer look!.
```
2. ##### Update  hosts file
Now update the IP of the VertualServer(`api Ingress`) to the /etc/hosts file.
```shell
sudo nano /etc/hosts
# Append the IP and domain mapping and save the file
# 10.103.118.7 api.example.com
```
3. ##### Test your IP mapping
Test your IP maping is working correctly. User teminal or browser to access `api.example.com`
```shell
# terminal
curl api.example.com
# Test Result
# Hello World

```

#### Verify Rate Limiting

1. Return to Locust and change the parameters in these fields:

- Number of users – 1000
- Spawn rate – 10
- Host – http:/example.com
- Click the Start swarming button to send traffic to Podinfo API and Podinfo Frontend.

In the Locust title bar at top left, observe how as the number of users climbs in the `STATUS` column, so does the value in `FAILURES` column. However, `the errors are no longer coming from Podinfo Frontend` but rather from `Podinfo API` because the rate limit set for the API means excessive requests are being rejected. In the trace at lower right you can see NGINX is returning the message `503 Service Temporarily Unavailable`, which is part of the rate‑limiting feature and can be customized. The API is rate limited, and the web application is always available. Well done!

### Bonus
### Deleting Helm Charts
1. List Installend Helm Charts
```shell
helm list -A
: '
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
api     nginx-api       1               2023-08-02 17:19:07.816268787 +0200 CAT deployed        nginx-ingress-0.17.1    3.1.1      
main    nginx           1               2023-08-01 18:05:50.077856578 +0200 CAT deployed        nginx-ingress-0.17.1    3.1.1      
web     nginx-web       1               2023-08-02 18:12:10.969188683 +0200 CAT deployed        nginx-ingress-0.17.1    3.1.1 
'
```

2. Delete Chart name
```shell
helm delete main
# Delete any chart in the list
```