wget -c https://github.com/arttor/helmify/releases/download/v0.4.8/helmify_Linux_x86_64.tar.gz -O - | tar -xz

kubectl exec httpbin-diffy-v2-6c6c5dd799-2kpq4 -- curl  -H 'Canonical-Resource : endpoint-test' http://httpbin-diffy:8880/get

kubectl port-forward svc/httpbin-diffy  8880
kubectl port-forward svc/httpbin-diffy  8888


kubectl port-forward svc/monitoring-grafana 3000:80

kubectl exec deployment/httpbin-diffy  -- curl  -H 'Canonical-Resource : endpoint-test3' http://httpbin-diffy:8885/headers


helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add  jaeger https://jaegertracing.github.io/helm-charts
helm repo add  prometheus https://prometheus-community.github.io/helm-charts
helm repo add   grafana https://grafana.github.io/helm-charts


minikube stop
minikube delete
minikube start --memory 8192 --cpus 2
