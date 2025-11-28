# Cursor Rules App - Makefile
# Simplify common development and deployment tasks

.PHONY: help install dev start init-db clean docker-build docker-run deploy-gcp deploy-gcp-local logs describe delete test

# Variables
APP_NAME := cursor-rules-app
REGION := us-central1
PORT := 3000
DOCKER_PORT := 8080
PROJECT_ID := cursor-rules-479622
IMAGE_NAME := gcr.io/$(PROJECT_ID)/$(APP_NAME)

# Default target - show help
help:
	@echo "🚀 Cursor Rules App - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Development:"
	@echo "  make install          - Install dependencies"
	@echo "  make init-db          - Initialize SQLite database"
	@echo "  make dev              - Start development server with hot reload"
	@echo "  make start            - Start production server"
	@echo "  make clean            - Clean generated files"
	@echo "  make test             - Run tests (placeholder)"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build     - Build Docker image locally"
	@echo "  make docker-run       - Run Docker container locally"
	@echo "  make docker-test      - Build and test Docker container"
	@echo "  make docker-shell     - Open shell in Docker container"
	@echo ""
	@echo "Google Cloud Run:"
	@echo "  make deploy-gcp       - Deploy to Cloud Run (Cloud Build)"
	@echo "  make deploy-gcp-local - Deploy to Cloud Run (local build)"
	@echo "  make logs             - View Cloud Run logs"
	@echo "  make describe         - Describe Cloud Run service"
	@echo "  make url              - Get Cloud Run service URL"
	@echo "  make delete           - Delete Cloud Run service"
	@echo "  make public           - Make service publicly accessible"
	@echo "  make private          - Require authentication"
	@echo "  make permissions      - View current IAM permissions"
	@echo ""
	@echo "Current GCP Project: $(PROJECT_ID)"
	@echo ""

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	npm install

# Initialize database
init-db:
	@echo "🗄️  Initializing database..."
	node src/init-db.js

# Start development server
dev:
	@echo "🚀 Starting development server..."
	@echo "Server will be available at http://localhost:$(PORT)"
	npm run dev

# Start production server
start:
	@echo "🚀 Starting production server..."
	npm start

# Clean generated files
clean:
	@echo "🧹 Cleaning generated files..."
	rm -rf node_modules
	rm -rf data
	rm -rf uploads
	rm -f *.log
	@echo "✓ Clean complete"

# Test (placeholder)
test:
	@echo "🧪 Running tests..."
	@echo "⚠️  No tests configured yet"

# Build Docker image locally
docker-build:
	@echo "🔨 Building Docker image..."
	docker build -t $(APP_NAME):latest .
	@echo "✓ Docker image built: $(APP_NAME):latest"

# Run Docker container locally
docker-run: docker-build
	@echo "🐳 Running Docker container..."
	@echo "Server will be available at http://localhost:$(DOCKER_PORT)"
	docker run -p $(DOCKER_PORT):$(DOCKER_PORT) --name $(APP_NAME) --rm $(APP_NAME):latest

# Build and test Docker container
docker-test: docker-build
	@echo "🧪 Testing Docker container..."
	@docker run -d -p $(DOCKER_PORT):$(DOCKER_PORT) --name $(APP_NAME)-test $(APP_NAME):latest
	@sleep 3
	@echo "Testing health endpoint..."
	@curl -f http://localhost:$(DOCKER_PORT)/api/tags || (docker stop $(APP_NAME)-test && exit 1)
	@docker stop $(APP_NAME)-test
	@echo "✓ Docker container test passed"

# Open shell in Docker container
docker-shell:
	@echo "🐚 Opening shell in Docker container..."
	docker run -it --rm $(APP_NAME):latest /bin/sh

# Deploy to Cloud Run using Cloud Build
deploy-gcp:
	@echo "🚀 Deploying to Google Cloud Run (Cloud Build)..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "❌ Error: No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"; \
		exit 1; \
	fi
	@echo "Project: $(PROJECT_ID)"
	@echo "Region: $(REGION)"
	@echo ""
	gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com
	gcloud builds submit --config=cloudbuild.yaml
	@echo ""
	@echo "✓ Deployment complete!"
	@make url

# Deploy to Cloud Run with local build
deploy-gcp-local:
	@echo "🚀 Deploying to Google Cloud Run (Local Build)..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "❌ Error: No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"; \
		exit 1; \
	fi
	@echo "Project: $(PROJECT_ID)"
	@echo "Region: $(REGION)"
	@echo ""
	@echo "📦 Building Docker image..."
	docker build -t $(IMAGE_NAME):latest .
	@echo ""
	@echo "🔐 Configuring Docker authentication..."
	gcloud auth configure-docker
	@echo ""
	@echo "📤 Pushing image to Container Registry..."
	docker push $(IMAGE_NAME):latest
	@echo ""
	@echo "🚀 Deploying to Cloud Run..."
	gcloud run deploy $(APP_NAME) \
		--image=$(IMAGE_NAME):latest \
		--region=$(REGION) \
		--platform=managed \
		--allow-unauthenticated \
		--memory=512Mi \
		--cpu=1 \
		--max-instances=10 \
		--min-instances=0 \
		--port=8080
	@echo ""
	@echo "✓ Deployment complete!"
	@make url

# View Cloud Run logs
logs:
	@echo "📋 Fetching Cloud Run logs..."
	gcloud run logs read $(APP_NAME) --region=$(REGION) --limit=50

# Follow Cloud Run logs
logs-follow:
	@echo "📋 Following Cloud Run logs (Ctrl+C to stop)..."
	gcloud run logs tail $(APP_NAME) --region=$(REGION)

# Describe Cloud Run service
describe:
	@echo "📊 Cloud Run service details:"
	@echo ""
	gcloud run services describe $(APP_NAME) --region=$(REGION)

# Get service URL
url:
	@echo "🌐 Cloud Run service URL:"
	@gcloud run services describe $(APP_NAME) --region=$(REGION) --format='value(status.url)' 2>/dev/null || echo "Service not found"

# Delete Cloud Run service
delete:
	@echo "🗑️  Deleting Cloud Run service..."
	@read -p "Are you sure you want to delete $(APP_NAME)? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		gcloud run services delete $(APP_NAME) --region=$(REGION) --quiet; \
		echo "✓ Service deleted"; \
	else \
		echo "Cancelled"; \
	fi

# Make service public (allow unauthenticated access)
public:
	@echo "🌐 Making service publicly accessible..."
	gcloud run services add-iam-policy-binding $(APP_NAME) \
		--region=$(REGION) \
		--member="allUsers" \
		--role="roles/run.invoker"
	@echo "✓ Service is now public"

# Make service private (require authentication)
private:
	@echo "🔒 Making service private..."
	gcloud run services remove-iam-policy-binding $(APP_NAME) \
		--region=$(REGION) \
		--member="allUsers" \
		--role="roles/run.invoker"
	@echo "✓ Service now requires authentication"

# Check service permissions
permissions:
	@echo "🔐 Current IAM Policy:"
	@gcloud run services get-iam-policy $(APP_NAME) --region=$(REGION)

# Set GCP project
set-project:
	@read -p "Enter GCP Project ID: " project; \
	gcloud config set project $$project
	@echo "✓ Project set to: $$(gcloud config get-value project)"

# Enable required GCP APIs
enable-apis:
	@echo "🔧 Enabling required GCP APIs..."
	gcloud services enable cloudbuild.googleapis.com
	gcloud services enable run.googleapis.com
	gcloud services enable containerregistry.googleapis.com
	@echo "✓ APIs enabled"

# Show current configuration
config:
	@echo "⚙️  Current Configuration"
	@echo "========================"
	@echo "App Name:       $(APP_NAME)"
	@echo "GCP Project:    $(PROJECT_ID)"
	@echo "Region:         $(REGION)"
	@echo "Local Port:     $(PORT)"
	@echo "Docker Port:    $(DOCKER_PORT)"
	@echo "Image Name:     $(IMAGE_NAME)"

# Quick setup for new development environment
setup: install init-db
	@echo ""
	@echo "✓ Setup complete! Run 'make dev' to start development server"

# Full deploy (with confirmation)
deploy: docker-test
	@echo ""
	@echo "Docker test passed! Ready to deploy to Cloud Run."
	@read -p "Deploy to GCP? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		make deploy-gcp; \
	else \
		echo "Cancelled"; \
	fi

