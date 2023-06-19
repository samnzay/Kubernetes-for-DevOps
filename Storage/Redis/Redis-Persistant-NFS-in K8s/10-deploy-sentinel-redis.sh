
kubectl apply -f redis-config.yaml -n <namespace>;
kubectl apply -f redis-deployment.yaml -n <namespace>;
kubectl apply -f sentinel-deployment.yaml -n <namespace>;