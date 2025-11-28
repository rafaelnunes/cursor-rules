#!/bin/bash

# Cursor Rules App - Google Cloud Run Deployment Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Cursor Rules App - Cloud Run Deployment"
echo "=========================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: No GCP project is set${NC}"
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}✓${NC} Using GCP Project: ${YELLOW}$PROJECT_ID${NC}"
echo ""

# Set variables
APP_NAME="cursor-rules-app"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$APP_NAME"

# Prompt for deployment method
echo "Choose deployment method:"
echo "1) Build and deploy with Cloud Build (recommended)"
echo "2) Build locally and deploy"
echo ""
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo ""
        echo "📦 Building and deploying with Cloud Build..."
        echo ""
        
        # Enable required APIs
        echo "Enabling required APIs..."
        gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com
        
        # Submit build
        gcloud builds submit --config=cloudbuild.yaml
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Deployment successful!${NC}"
            
            # Get the service URL
            SERVICE_URL=$(gcloud run services describe $APP_NAME --region=$REGION --format='value(status.url)' 2>/dev/null)
            
            if [ ! -z "$SERVICE_URL" ]; then
                echo ""
                echo -e "${GREEN}🌐 Your app is live at:${NC}"
                echo -e "${YELLOW}$SERVICE_URL${NC}"
            fi
        else
            echo -e "${RED}✗ Deployment failed${NC}"
            exit 1
        fi
        ;;
        
    2)
        echo ""
        echo "🔨 Building Docker image locally..."
        echo ""
        
        # Build the image
        docker build -t $IMAGE_NAME .
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Docker build failed${NC}"
            exit 1
        fi
        
        echo ""
        echo "📤 Pushing image to Container Registry..."
        echo ""
        
        # Configure docker for GCR
        gcloud auth configure-docker
        
        # Push the image
        docker push $IMAGE_NAME
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Docker push failed${NC}"
            exit 1
        fi
        
        echo ""
        echo "🚀 Deploying to Cloud Run..."
        echo ""
        
        # Deploy to Cloud Run
        gcloud run deploy $APP_NAME \
            --image=$IMAGE_NAME \
            --region=$REGION \
            --platform=managed \
            --allow-unauthenticated \
            --memory=512Mi \
            --cpu=1 \
            --max-instances=10 \
            --min-instances=0 \
            --port=8080
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Deployment successful!${NC}"
            
            # Get the service URL
            SERVICE_URL=$(gcloud run services describe $APP_NAME --region=$REGION --format='value(status.url)' 2>/dev/null)
            
            if [ ! -z "$SERVICE_URL" ]; then
                echo ""
                echo -e "${GREEN}🌐 Your app is live at:${NC}"
                echo -e "${YELLOW}$SERVICE_URL${NC}"
            fi
        else
            echo -e "${RED}✗ Deployment failed${NC}"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "📊 Useful commands:"
echo "  View logs:    gcloud run logs read $APP_NAME --region=$REGION"
echo "  View service: gcloud run services describe $APP_NAME --region=$REGION"
echo "  Delete:       gcloud run services delete $APP_NAME --region=$REGION"
echo ""
