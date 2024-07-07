## Create
kubectl apply -f ./.devcontainer/k8s/
kubectl describe pod sera-pod -n default

## Remove
kubectl delete pod sera-pod -n default
kubectl delete pvc --all -n default
kubectl delete pv --all -n default

## Debug
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
# Inside the temporary pod
wget -qO- https://10.1.0.58:32010
