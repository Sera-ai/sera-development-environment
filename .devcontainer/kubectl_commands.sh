## Create
kubectl apply -f ./.devcontainer/k8s/
kubectl describe pod sera-pod -n sera-namespace

## Remove
kubectl delete pod sera-pod -n sera-namespace
kubectl delete pvc --all -n sera-namespace
kubectl delete pv --all -n sera-namespace

## Debug
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
# Inside the temporary pod
wget -qO- https://10.1.0.58:32010
