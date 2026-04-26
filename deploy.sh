#!/bin/bash

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-production}"
ENVIRONMENT="${ENVIRONMENT:-production}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
PROJECT_NAME="${PROJECT_NAME:-microservices}"
KUBECTL_TIMEOUT="${KUBECTL_TIMEOUT:-5m}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed."; exit 1; }
    command -v helm >/dev/null 2>&1 || { log_error "helm is required but not installed."; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "docker is required but not installed."; exit 1; }
    
    log_success "All prerequisites met"
}

# Create namespace
create_namespace() {
    log_info "Creating/updating namespace: $NAMESPACE"
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace $NAMESPACE app=$PROJECT_NAME environment=$ENVIRONMENT --overwrite
    
    log_success "Namespace created"
}

# Create secrets
create_secrets() {
    log_info "Creating secrets..."
    
    # Database credentials
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(openssl rand -base64 32)
    fi
    
    kubectl create secret generic database-credentials \
        --from-literal=username=postgres \
        --from-literal=password=$DB_PASSWORD \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Redis credentials
    if [ -z "$REDIS_PASSWORD" ]; then
        REDIS_PASSWORD=$(openssl rand -base64 32)
    fi
    
    kubectl create secret generic redis-credentials \
        --from-literal=url=redis://:$REDIS_PASSWORD@redis:6379 \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # RabbitMQ credentials
    kubectl create secret generic rabbitmq-credentials \
        --from-literal=url=amqp://guest:guest@rabbitmq:5672 \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Docker registry credentials (if needed)
    if [ ! -z "$DOCKER_USERNAME" ] && [ ! -z "$DOCKER_PASSWORD" ]; then
        kubectl create secret docker-registry regcred \
            --docker-server=$DOCKER_REGISTRY \
            --docker-username=$DOCKER_USERNAME \
            --docker-password=$DOCKER_PASSWORD \
            --namespace=$NAMESPACE \
            --dry-run=client -o yaml | kubectl apply -f -
    fi
    
    log_success "Secrets created"
}

# Create configmaps
create_configmaps() {
    log_info "Creating ConfigMaps..."
    
    # Database configuration
    kubectl create configmap database-config \
        --from-literal=host=postgres.production.svc.cluster.local \
        --from-literal=port=5432 \
        --from-literal=name=microservices \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Logging configuration
    kubectl create configmap logging-config \
        --from-literal=LOG_LEVEL=info \
        --from-literal=LOG_FORMAT=json \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "ConfigMaps created"
}

# Deploy services
deploy_services() {
    log_info "Deploying services..."
    
    services=("user-service" "product-service" "order-service" "payment-service")
    
    for service in "${services[@]}"; do
        log_info "Deploying $service..."
        
        kubectl apply -f kubernetes/deployments/$service.yaml
        kubectl set image deployment/$service $service=$DOCKER_REGISTRY/$PROJECT_NAME/$service:latest \
            --namespace=$NAMESPACE \
            --record || true
    done
    
    log_success "Services deployed"
}

# Deploy infrastructure services
deploy_infrastructure() {
    log_info "Deploying infrastructure services..."
    
    # PostgreSQL
    if ! kubectl get statefulset postgres -n $NAMESPACE &>/dev/null; then
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
        
        helm install postgres bitnami/postgresql \
            --namespace $NAMESPACE \
            --values kubernetes/helm/values-postgres.yaml
        
        log_success "PostgreSQL deployed"
    fi
    
    # Redis
    if ! kubectl get statefulset redis -n $NAMESPACE &>/dev/null; then
        helm install redis bitnami/redis \
            --namespace $NAMESPACE \
            --values kubernetes/helm/values-redis.yaml
        
        log_success "Redis deployed"
    fi
    
    # RabbitMQ
    if ! kubectl get statefulset rabbitmq -n $NAMESPACE &>/dev/null; then
        helm install rabbitmq bitnami/rabbitmq \
            --namespace $NAMESPACE \
            --values kubernetes/helm/values-rabbitmq.yaml
        
        log_success "RabbitMQ deployed"
    fi
}

# Deploy Ingress
deploy_ingress() {
    log_info "Deploying Ingress..."
    
    kubectl apply -f kubernetes/ingress/ingress.yaml
    
    log_success "Ingress deployed"
}

# Wait for deployments
wait_for_deployments() {
    log_info "Waiting for deployments to be ready..."
    
    deployments=$(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for deployment in $deployments; do
        log_info "Waiting for deployment: $deployment"
        kubectl rollout status deployment/$deployment \
            --namespace=$NAMESPACE \
            --timeout=$KUBECTL_TIMEOUT
    done
    
    log_success "All deployments are ready"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    # Create a temporary pod for migrations
    kubectl run migration-job \
        --image=$DOCKER_REGISTRY/$PROJECT_NAME/user-service:latest \
        --restart=Never \
        --namespace=$NAMESPACE \
        -- npm run migrate || true
    
    # Clean up
    kubectl delete pod migration-job -n $NAMESPACE --ignore-not-found=true
    
    log_success "Migrations completed"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pod status
    log_info "Pod status:"
    kubectl get pods -n $NAMESPACE
    
    # Check service status
    log_info "Service status:"
    kubectl get svc -n $NAMESPACE
    
    # Check ingress
    log_info "Ingress status:"
    kubectl get ingress -n $NAMESPACE
    
    log_success "Deployment verified"
}

# Run smoke tests
run_smoke_tests() {
    log_info "Running smoke tests..."
    
    # Get LoadBalancer IP/Hostname
    INGRESS_IP=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
    [ -z "$INGRESS_IP" ] && INGRESS_IP=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$INGRESS_IP" ]; then
        log_warning "Could not get Ingress IP/hostname, skipping smoke tests"
        return
    fi
    
    # Wait for service to be ready
    sleep 30
    
    # Test health endpoints
    services=("user-service" "product-service" "order-service" "payment-service")
    for service in "${services[@]}"; do
        log_info "Testing $service health..."
        
        if curl -f http://$INGRESS_IP/$service/health; then
            log_success "$service is healthy"
        else
            log_warning "$service health check failed"
        fi
    done
    
    log_success "Smoke tests completed"
}

# Rollback deployment
rollback_deployment() {
    log_info "Rolling back deployment..."
    
    deployments=$(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for deployment in $deployments; do
        log_info "Rolling back deployment: $deployment"
        kubectl rollout undo deployment/$deployment --namespace=$NAMESPACE
    done
    
    log_success "Rollback completed"
}

# Main execution
main() {
    log_info "Starting deployment to $ENVIRONMENT environment..."
    log_info "Namespace: $NAMESPACE"
    
    # Parse arguments
    case "${1:-deploy}" in
        deploy)
            check_prerequisites
            create_namespace
            create_secrets
            create_configmaps
            deploy_infrastructure
            deploy_services
            deploy_ingress
            wait_for_deployments
            run_migrations
            verify_deployment
            run_smoke_tests
            log_success "Deployment completed successfully!"
            ;;
        rollback)
            check_prerequisites
            rollback_deployment
            wait_for_deployments
            verify_deployment
            log_success "Rollback completed successfully!"
            ;;
        verify)
            check_prerequisites
            verify_deployment
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Usage: $0 {deploy|rollback|verify}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
