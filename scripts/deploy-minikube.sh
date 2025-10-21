echo "Deploying to Minikube"

if ! minikube status > /dev/null 2>&1; then
    echo "Minikube is not running. Starting Minikube..."
    minikube start
fi

echo "Setting up Docker environment for Minikube..."
eval $(minikube docker-env)

echo "Building Docker images locally..."
docker build -t auth-service:latest ./backend/authentification_service
docker build -t data-service:latest ./backend/data_service
docker build -t processing-service:latest ./backend/processing_service
docker build -t frontend:latest ./frontend

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/deployment.yaml

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n scidata --timeout=60s
kubectl wait --for=condition=ready pod -l app=auth-service -n scidata --timeout=60s
kubectl wait --for=condition=ready pod -l app=data-service -n scidata --timeout=60s
kubectl wait --for=condition=ready pod -l app=processing-service -n scidata --timeout=60s
kubectl wait --for=condition=ready pod -l app=frontend -n scidata --timeout=60s

echo "Pod status:"
kubectl get pods -n scidata

echo "Services:"
kubectl get services -n scidata

echo "Ingress:"
kubectl get ingress -n scidata

echo "Getting application URL..."
MINIKUBE_IP=$(minikube ip)
FRONTEND_PORT=$(kubectl get service frontend -n scidata -o jsonpath='{.spec.ports[0].nodePort}')

echo "Deployment complete!"
echo "Application URL: http://$MINIKUBE_IP:$FRONTEND_PORT"
echo "Or add to /etc/hosts: $MINIKUBE_IP scidata.local"
echo "Then access: http://scidata.local"

echo "To view logs:"
echo "kubectl logs -f deployment/auth-service -n scidata"
echo "kubectl logs -f deployment/data-service -n scidata"
echo "kubectl logs -f deployment/processing-service -n scidata"
echo "kubectl logs -f deployment/frontend -n scidata"
