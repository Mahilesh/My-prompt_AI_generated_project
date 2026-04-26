#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        echo "Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        echo "Please install Docker from https://www.docker.com/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    log_success "All prerequisites are installed"
    
    # Display versions
    log_info "Versions:"
    echo "  Node.js: $(node -v)"
    echo "  npm: $(npm -v)"
    echo "  Docker: $(docker --version)"
    echo "  Docker Compose: $(docker-compose --version)"
}

# Create .env file
create_env_file() {
    log_info "Setting up environment variables..."
    
    if [ -f ".env" ]; then
        log_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    cp .env.example .env
    
    # Generate secure passwords
    DB_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Update .env with generated values (Unix/Linux/Mac compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
        sed -i '' "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" .env
        sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    else
        # Linux
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
        sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" .env
        sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    fi
    
    log_success ".env file created"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    services=("user-service" "product-service" "order-service" "payment-service" "api-gateway")
    
    for service in "${services[@]}"; do
        if [ -d "src/$service" ]; then
            log_info "Installing dependencies for $service..."
            (cd "src/$service" && npm ci)
            log_success "$service dependencies installed"
        fi
    done
}

# Start infrastructure services
start_infrastructure() {
    log_info "Starting infrastructure services with Docker Compose..."
    
    docker-compose -f docker-compose.yml up -d
    
    log_success "Infrastructure services started"
    log_info "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    log_info "Waiting for PostgreSQL..."
    max_attempts=30
    attempt=1
    while ! docker exec postgres_db pg_isready -U postgres &>/dev/null; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "PostgreSQL failed to start"
            exit 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    log_success "PostgreSQL is ready"
    
    # Wait for MongoDB
    log_info "Waiting for MongoDB..."
    max_attempts=30
    attempt=1
    while ! docker exec mongodb mongosh localhost --eval "db.runCommand('ping')" &>/dev/null; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "MongoDB failed to start"
            exit 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    log_success "MongoDB is ready"
    
    # Wait for Redis
    log_info "Waiting for Redis..."
    max_attempts=30
    attempt=1
    while ! docker exec redis_cache redis-cli ping &>/dev/null; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "Redis failed to start"
            exit 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    log_success "Redis is ready"
    
    # Wait for RabbitMQ
    log_info "Waiting for RabbitMQ..."
    max_attempts=30
    attempt=1
    while ! docker exec rabbitmq rabbitmq-diagnostics -q ping &>/dev/null; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "RabbitMQ failed to start"
            exit 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    log_success "RabbitMQ is ready"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    # Wait a bit for PostgreSQL connection to be stable
    sleep 5
    
    # Create databases and schemas
    docker exec postgres_db psql -U postgres -c "CREATE DATABASE microservices;" || true
    
    log_success "Database migrations completed"
}

# Display service URLs
display_service_urls() {
    log_info "Services are running at:"
    echo ""
    echo "Core Services:"
    echo "  API Gateway:         http://localhost:3000"
    echo "  User Service:        http://localhost:3001"
    echo "  Product Service:     http://localhost:3002"
    echo "  Order Service:       http://localhost:3003"
    echo ""
    echo "Infrastructure:"
    echo "  PostgreSQL:          localhost:5432 (user: postgres)"
    echo "  MongoDB:             localhost:27017 (user: admin)"
    echo "  Redis:               localhost:6379"
    echo "  RabbitMQ:            http://localhost:15672 (user: guest, pass: guest)"
    echo "  Elasticsearch:       http://localhost:9200"
    echo "  Kibana:              http://localhost:5601"
    echo ""
    echo "Monitoring:"
    echo "  Prometheus:          http://localhost:9090"
    echo "  Grafana:             http://localhost:3100 (user: admin, pass: admin)"
    echo ""
}

# Display next steps
display_next_steps() {
    log_success "Local development environment is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Start individual services for development:"
    echo "   cd src/user-service && npm run dev"
    echo ""
    echo "2. Or use Docker Compose services directly"
    echo ""
    echo "3. View logs:"
    echo "   docker-compose logs -f user-service"
    echo ""
    echo "4. Stop services:"
    echo "   docker-compose down"
    echo ""
    echo "5. Access the services at the URLs listed above"
    echo ""
    echo "6. For more information, see README.md"
    echo ""
}

# Main
main() {
    log_info "Setting up local development environment..."
    echo ""
    
    check_prerequisites
    create_env_file
    install_dependencies
    start_infrastructure
    run_migrations
    
    display_service_urls
    display_next_steps
}

# Run main
main
