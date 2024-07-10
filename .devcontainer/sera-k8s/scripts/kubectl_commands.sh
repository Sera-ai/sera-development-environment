## Create
kubectl apply -f ./.devcontainer/k8s/
kubectl describe pod sera-pod -n sera-namespace






## Remove
kubectl delete job --all -n sera-namespace
kubectl delete statefulset --all -n sera-namespace
kubectl delete deployment --all -n sera-namespace
kubectl delete pod --all -n sera-namespace
kubectl delete service --all -n sera-namespace
kubectl delete pvc --all -n sera-namespace
kubectl delete pv --all -n sera-namespace
kubectl delete storageclass --all -n sera-namespace
kubectl delete ingressclass --all -n sera-namespace
kubectl delete configmap --all -n sera-namespace
kubectl delete role --all -n sera-namespace
kubectl delete rolebinding --all -n sera-namespace
kubectl delete secret --all -n sera-namespace
kubectl delete serviceaccount --all -n sera-namespace
kubectl delete networkpolicy --all -n sera-namespace
kubectl delete ingress --all -n sera-namespace
kubectl delete resourcequota --all -n sera-namespace
kubectl delete limitrange --all -n sera-namespace
kubectl delete hpa --all -n sera-namespace
kubectl apply -f ./k8s/






## Debug
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh