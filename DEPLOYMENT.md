# Deployment Guide

Complete guide for deploying Cursor Rules App to Google Cloud Run.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Docker Setup](#docker-setup)
- [Google Cloud Run Deployment](#google-cloud-run-deployment)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

1. **Google Cloud SDK**
   ```bash
   # Install gcloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Verify installation
   gcloud --version
   ```

2. **Docker** (for local testing)
   ```bash
   # Verify installation
   docker --version
   ```

3. **Make** (optional, for simplified commands)
   ```bash
   # Verify installation
   make --version
   ```

### Google Cloud Setup

1. **Create/Select a GCP Project**
   ```bash
   # Set your project ID
   gcloud config set project YOUR_PROJECT_ID
   
   # Or using Makefile
   make set-project
   ```

2. **Enable Required APIs**
   ```bash
   # Manual
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   
   # Or using Makefile
   make enable-apis
   ```

3. **Authenticate**
   ```bash
   gcloud auth login
   gcloud auth configure-docker
   ```

## Docker Setup

### Local Testing

Test the Docker container locally before deploying:

```bash
# Build the image
make docker-build

# Run locally (accessible at http://localhost:8080)
make docker-run

# Or run tests
make docker-test
```

### Manual Docker Commands

```bash
# Build
docker build -t cursor-rules-app .

# Run
docker run -p 8080:8080 cursor-rules-app

# Test
curl http://localhost:8080/api/tags
```

## Google Cloud Run Deployment

### Option 1: Cloud Build (Recommended)

Builds the image in the cloud using Google Cloud Build:

```bash
# Deploy with Makefile
make deploy-gcp

# Or manually
gcloud builds submit --config=cloudbuild.yaml
```

**Advantages:**
- No local Docker required
- Faster for slow internet connections
- Consistent build environment
- Build logs stored in Cloud Console

### Option 2: Local Build

Builds the image locally and pushes to GCR:

```bash
# Deploy with Makefile
make deploy-gcp-local

# Or manually
docker build -t gcr.io/YOUR_PROJECT_ID/cursor-rules-app .
docker push gcr.io/YOUR_PROJECT_ID/cursor-rules-app
gcloud run deploy cursor-rules-app \
  --image gcr.io/YOUR_PROJECT_ID/cursor-rules-app \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated
```

**Advantages:**
- Full control over build process
- Can test locally before pushing
- Faster for good internet connections

### Option 3: Interactive Script

```bash
./deploy.sh
```

Follow the interactive prompts to deploy.

## Configuration

### Environment Variables

Cloud Run automatically sets:
- `PORT=8080` - Server port
- `NODE_ENV=production` - Environment mode

To add custom environment variables:

```bash
gcloud run deploy cursor-rules-app \
  --update-env-vars KEY1=VALUE1,KEY2=VALUE2
```

### Resource Limits

Default configuration (in `cloudbuild.yaml` and `Makefile`):
- Memory: 512Mi
- CPU: 1
- Max instances: 10
- Min instances: 0 (scales to zero)

To modify:

```bash
gcloud run deploy cursor-rules-app \
  --memory 1Gi \
  --cpu 2 \
  --max-instances 20
```

### Custom Domain

1. Verify domain ownership in GCP
2. Map domain to Cloud Run service:

```bash
gcloud run domain-mappings create \
  --service cursor-rules-app \
  --domain your-domain.com \
  --region us-central1
```

## Monitoring

### View Logs

```bash
# Last 50 logs
make logs

# Follow logs in real-time
make logs-follow

# Manual
gcloud run logs read cursor-rules-app --region us-central1 --limit 50
gcloud run logs tail cursor-rules-app --region us-central1
```

### Service Details

```bash
# Get service information
make describe

# Get service URL
make url

# View in Cloud Console
gcloud run services describe cursor-rules-app \
  --region us-central1 \
  --format yaml
```

### Cloud Console

View detailed metrics at:
```
https://console.cloud.google.com/run/detail/us-central1/cursor-rules-app
```

Metrics include:
- Request count
- Request latency
- Container instance count
- CPU/Memory utilization
- Error rates

## Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
# Ensure you're authenticated
gcloud auth login

# Check current project
gcloud config get-value project
```

**2. Build Fails**
```bash
# Check build logs
gcloud builds list --limit 5
gcloud builds log [BUILD_ID]

# Test Docker build locally
make docker-test
```

**3. Service Not Accessible**
```bash
# Check service status
gcloud run services describe cursor-rules-app --region us-central1

# Check if service is public
gcloud run services get-iam-policy cursor-rules-app --region us-central1

# Make service public
gcloud run services add-iam-policy-binding cursor-rules-app \
  --region us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

**4. Database Issues**

SQLite database is ephemeral in Cloud Run (resets on restart). For production:
- Use Cloud SQL (PostgreSQL/MySQL)
- Use Firestore
- Mount a persistent volume (beta)

**5. Upload Directory**

Uploaded files are ephemeral. For production:
- Use Cloud Storage
- Store files in a persistent storage solution

### Health Check

Test the deployed service:

```bash
# Get URL
SERVICE_URL=$(gcloud run services describe cursor-rules-app \
  --region us-central1 \
  --format 'value(status.url)')

# Test endpoints
curl $SERVICE_URL/api/tags
curl $SERVICE_URL/api/rules
```

## Production Considerations

### Persistence

Current setup uses ephemeral storage. For production:

1. **Database**: Migrate to Cloud SQL
   ```bash
   # Create Cloud SQL instance
   gcloud sql instances create cursor-rules-db \
     --database-version=POSTGRES_14 \
     --cpu=1 \
     --memory=3840MB \
     --region=us-central1
   ```

2. **File Storage**: Use Cloud Storage
   ```javascript
   // Update server.js to use Cloud Storage
   const { Storage } = require('@google-cloud/storage');
   const storage = new Storage();
   const bucket = storage.bucket('cursor-rules-uploads');
   ```

### Security

1. **Add Authentication**
   - Use Cloud Identity Platform
   - Add OAuth 2.0
   - Implement API keys

2. **HTTPS Only**
   Cloud Run enforces HTTPS by default

3. **Environment Secrets**
   ```bash
   # Use Secret Manager
   gcloud secrets create db-password --data-file=-
   
   # Reference in Cloud Run
   gcloud run deploy cursor-rules-app \
     --update-secrets=DB_PASSWORD=db-password:latest
   ```

### Scaling

```bash
# Set minimum instances for faster response
gcloud run services update cursor-rules-app \
  --min-instances 1 \
  --region us-central1

# Set concurrency
gcloud run services update cursor-rules-app \
  --concurrency 80 \
  --region us-central1
```

## Cost Optimization

Cloud Run pricing:
- Pay per use (scales to zero)
- Free tier: 2 million requests/month
- Optimize by:
  - Setting appropriate memory/CPU
  - Using min-instances=0 for dev
  - Implementing caching

## Cleanup

Delete all resources:

```bash
# Delete Cloud Run service
make delete

# Or manually
gcloud run services delete cursor-rules-app --region us-central1

# Delete container images
gcloud container images delete gcr.io/YOUR_PROJECT_ID/cursor-rules-app
```

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Container Registry Documentation](https://cloud.google.com/container-registry/docs)
- [Cloud Run Pricing](https://cloud.google.com/run/pricing)

