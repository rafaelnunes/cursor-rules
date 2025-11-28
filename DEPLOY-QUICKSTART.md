# 🚀 Quick Deploy Guide

## 5-Minute Deployment to Google Cloud Run

### Step 1: Prerequisites (One-time setup)

```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
make enable-apis
```

### Step 2: Deploy

Choose your preferred method:

**Method A: Cloud Build (Easiest)**
```bash
make deploy-gcp
```

**Method B: Local Build**
```bash
make deploy-gcp-local
```

**Method C: Interactive Script**
```bash
./deploy.sh
```

### Step 3: Get Your URL

```bash
make url
```

**That's it! Your app is live! 🎉**

---

## Common Commands

```bash
# Development
make dev              # Run locally (port 3000)
make docker-run       # Test Docker locally (port 8080)

# Deploy
make deploy-gcp       # Deploy to Cloud Run

# Monitor
make logs             # View recent logs
make logs-follow      # Follow logs in real-time
make describe         # Service details
make url              # Get live URL

# Manage
make delete           # Delete service (with confirmation)
```

---

## Troubleshooting

**No GCP project set?**
```bash
make set-project
```

**Build fails?**
```bash
make docker-test      # Test locally first
```

**Need to see what's happening?**
```bash
make logs-follow
```

---

## What Gets Deployed?

✅ Node.js Express server  
✅ SQLite database (initialized)  
✅ Alpine.js frontend  
✅ All API endpoints  
✅ File upload system  
✅ Tag filtering & search  

## Default Configuration

- **Region:** us-central1
- **Memory:** 512Mi
- **CPU:** 1 core
- **Auto-scaling:** 0-10 instances
- **Access:** Public (no auth required)

## Cost

Cloud Run offers a generous free tier:
- 2 million requests/month
- 360,000 GB-seconds/month
- Scales to zero when not in use

For this app's typical usage: **~$0-5/month**

---

## Next Steps

After deployment, consider:

1. **Add a custom domain**
   ```bash
   gcloud run domain-mappings create \
     --service cursor-rules-app \
     --domain your-domain.com
   ```

2. **Monitor usage**
   - View in [Cloud Console](https://console.cloud.google.com/run)

3. **Scale for production**
   ```bash
   # Keep 1 instance always running for faster response
   gcloud run services update cursor-rules-app \
     --min-instances 1 \
     --region us-central1
   ```

4. **Add persistence** (for production)
   - Migrate to Cloud SQL for database
   - Use Cloud Storage for uploads
   - See [DEPLOYMENT.md](DEPLOYMENT.md) for details

---

## Full Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [README.md](README.md) - Full project documentation
- [Makefile](Makefile) - All available commands

## Support

Run `make help` anytime to see all available commands.

**Questions?** Check the [Makefile](Makefile) for detailed command definitions.

