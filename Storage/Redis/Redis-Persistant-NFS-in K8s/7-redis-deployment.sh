kubectl apply -f redis-config.yaml -n dev;
kubectl apply -f redis-deployment.yaml -n dev;

kubectl get pods -n dev;