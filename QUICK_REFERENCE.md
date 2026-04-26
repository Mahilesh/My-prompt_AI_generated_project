# Project Files Reference Guide

## 📦 Complete Microservices Architecture Package

This package contains everything you need to deploy a production-grade microservices architecture on Kubernetes with complete DevOps, monitoring, and CI/CD setup.

## 📋 Files Included

### 📄 Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Main project documentation with quick start guide |
| `ARCHITECTURE.md` | Detailed architecture documentation and system design |
| `.env.example` | Environment variables template |

### 🐳 Docker Configuration

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Complete local development environment with all services |
| `Dockerfile.prod` | Production-ready multi-stage Docker image |

### ☸️ Kubernetes Manifests

| File | Purpose |
|------|---------|
| `user-service-deployment.yaml` | Complete K8s deployment for user service with HPA and PDB |
| `kubernetes-ingress.yaml` | Ingress configuration with TLS, routing rules, and network policies |

### 🏗️ Infrastructure as Code (Terraform)

| File | Purpose |
|------|---------|
| `terraform-main.tf` | Main Terraform configuration for AWS infrastructure |
| `terraform-variables.tf` | Variable definitions for Terraform |

### 🔄 CI/CD Pipeline

| File | Purpose |
|------|---------|
| `github-actions-build-deploy.yml` | GitHub Actions workflow for build, test, and deployment |

### 📊 Monitoring & Observability

| File | Purpose |
|------|---------|
| `prometheus.yml` | Prometheus configuration for metrics collection |
| `prometheus-alerts.yml` | Alert rules for Prometheus |

### 🛠️ Scripts

| File | Purpose |
|------|---------|
| `deploy.sh` | Kubernetes deployment automation script |
| `setup-local.sh` | Local development environment setup script |

### 💻 Application Templates

| File | Purpose |
|------|---------|
| `package.json.example` | Example Node.js service configuration |

## 🚀 Quick Start

### 1. Local Development Setup

```bash
# Make setup script executable
chmod +x setup-local.sh

# Run setup
./setup-local.sh

# This will:
# - Check prerequisites (Node.js, Docker, Docker Compose)
# - Create .env file with secure passwords
# - Install dependencies for all services
# - Start infrastructure (PostgreSQL, MongoDB, Redis, RabbitMQ, etc.)
# - Run database migrations
# - Display service URLs
```

### 2. Deploy to Kubernetes

```bash
# Make deployment script executable
chmod +x deploy.sh

# Deploy to production
./deploy.sh deploy

# Verify deployment
./deploy.sh verify

# Rollback if needed
./deploy.sh rollback
```

### 3. Deploy Infrastructure with Terraform

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Get outputs (RDS endpoint, etc.)
terraform output
```

## 📁 Directory Structure to Create

After extracting these files, create this directory structure:

```
microservices-architecture/
├── src/
│   ├── api-gateway/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── user-service/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── product-service/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── order-service/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── payment-service/
│       ├── Dockerfile
│       └── package.json
├── kubernetes/
│   ├── deployments/
│   ├── services/
│   ├── configmaps/
│   ├── secrets/
│   ├── ingress/
│   └── helm/
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── alerts.yml
│   └── grafana/
│       └── dashboards/
├── cicd/
│   └── github/
│       └── workflows/
│           └── build-deploy.yml
├── docker/
│   ├── Dockerfile.dev
│   └── Dockerfile.prod
├── scripts/
│   ├── deploy.sh
│   ├── setup-local.sh
│   └── backup.sh
├── config/
│   ├── .env.example
│   └── database-config.yaml
├── docker-compose.yml
├── README.md
├── ARCHITECTURE.md
└── .gitignore
```

## 🔧 Service URLs (Local Development)

After running `setup-local.sh`, services will be available at:

### Core Services
- **API Gateway**: http://localhost:3000
- **User Service**: http://localhost:3001
- **Product Service**: http://localhost:3002
- **Order Service**: http://localhost:3003

### Databases
- **PostgreSQL**: localhost:5432 (user: postgres)
- **MongoDB**: localhost:27017 (user: admin)
- **Redis**: localhost:6379

### Message Queue
- **RabbitMQ**: http://localhost:15672 (user: guest, pass: guest)

### Search & Logs
- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601

### Monitoring
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3100 (user: admin, pass: admin)

## 📋 Configuration Steps

### 1. Update `.env` File
```bash
# After setup-local.sh creates .env, update these:
- Database credentials
- API keys for payment providers
- Email service credentials
- Any third-party API keys
```

### 2. Configure Kubernetes Secrets
```bash
# Create Kubernetes secrets for production
kubectl create secret generic database-credentials \
  --from-literal=username=postgres \
  --from-literal=password=<secure-password>
```

### 3. Update Terraform Variables
```bash
# Edit terraform-variables.tf or create terraform.tfvars
# Update AWS region, VPC CIDR, instance types, etc.
```

### 4. Configure GitHub Actions
```bash
# Set these secrets in GitHub repository:
- AWS_ROLE_TO_ASSUME_PRODUCTION
- AWS_ROLE_TO_ASSUME_STAGING
- ARGOCD_TOKEN
- SLACK_WEBHOOK
- SONAR_TOKEN
```

## 🧪 Testing

### Run Tests
```bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Security scanning
npm run security:scan
```

## 📊 Monitoring

### Metrics
- CPU and memory usage
- Request latency and error rates
- Database performance
- Cache hit rates
- Queue depths

### Dashboards
- Service health overview
- Infrastructure monitoring
- Application performance
- Business metrics

### Alerts
- Service unavailability
- High error rates
- Resource exhaustion
- Database issues

## 🔒 Security

### Implemented
- Network policies for pod communication
- RBAC for Kubernetes access
- Secrets encryption at rest
- TLS encryption in transit
- Regular security scanning
- Container image vulnerability scanning

### To Configure
- AWS WAF rules
- Database backup encryption
- SSL/TLS certificates
- API key management

## 🚀 Deployment Strategies

### Rolling Update
Services are updated gradually without downtime (default)

### Canary Deployment
New version runs alongside old, gradually shifting traffic

### Blue-Green
Two identical environments, quick switch between them

### Automatic Rollback
Failed deployments automatically roll back to previous version

## 💾 Backup & Recovery

### Automated Backups
- Daily database backups
- 30-day retention
- Cross-region replication
- Point-in-time recovery

### Manual Backup
```bash
bash scripts/backup.sh
```

## 📚 Additional Resources

### Documentation
- [OpenTelemetry Demo Architecture](https://opentelemetry.io/docs/demo/architecture/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Docker Documentation](https://docs.docker.com/)

### Tools Used
- **Kubernetes**: Container orchestration
- **Docker**: Containerization
- **Terraform**: Infrastructure as Code
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ELK Stack**: Log aggregation
- **GitHub Actions**: CI/CD
- **ArgoCD**: GitOps deployment

## 🆘 Troubleshooting

### Common Issues

1. **Services not starting**
   - Check Docker is running: `docker ps`
   - Check port conflicts: `lsof -i :3000`
   - View logs: `docker-compose logs -f`

2. **Database connection errors**
   - Verify credentials in .env
   - Check database is running: `docker ps | grep postgres`
   - Test connection: `psql -h localhost -U postgres`

3. **Kubernetes deployment issues**
   - Check pod status: `kubectl get pods -n production`
   - View logs: `kubectl logs <pod-name> -n production`
   - Describe pod: `kubectl describe pod <pod-name> -n production`

4. **Permission denied errors**
   - Make scripts executable: `chmod +x *.sh`
   - Check Docker permissions: `docker ps`

### Getting Help

- Check logs: `docker-compose logs <service-name>`
- View Kubernetes events: `kubectl describe node <node-name>`
- Check metrics in Prometheus: http://localhost:9090
- Review dashboards in Grafana: http://localhost:3100

## 📝 Maintenance

### Regular Tasks
- Review and update dependencies monthly
- Run security scans regularly
- Monitor disk usage and cleanup old logs
- Test backup and recovery procedures
- Review and update alert thresholds

### Performance Tuning
- Monitor metrics and identify bottlenecks
- Adjust resource requests/limits
- Scale services based on load
- Optimize database queries
- Adjust cache TTLs

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs and metrics
3. Consult architecture documentation
4. Check GitHub Issues
5. Contact the platform engineering team

---

**Version**: 1.0.0  
**Last Updated**: 2026-04-26  
**Maintained By**: Platform Engineering Team
