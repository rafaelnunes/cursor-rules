# Cursor Rules Share

Share and Discover Cursor IDE rules.

## 🛠️ Installation

### Quick Setup
```bash
make setup      # Install dependencies and initialize database
make dev        # Start development server
```

### Manual Setup
1. Install dependencies:
```bash
npm install
```

2. Initialize the database:
```bash
npm run init-db
```

3. Start the server:
```bash
npm run dev
```

4. Access: http://localhost:3000

## 🐳 Docker Deployment

### Local Docker Testing
```bash
make docker-build    # Build Docker image
make docker-run      # Run container locally (port 8080)
make docker-test     # Test Docker container
```

## ☁️ Google Cloud Run Deployment

### Prerequisites
- Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Set your GCP project: `gcloud config set project YOUR_PROJECT_ID`
- Enable required APIs: `make enable-apis`

### Deploy Options

**Option 1: Cloud Build (Recommended)**
```bash
make deploy-gcp
```

**Option 2: Local Build**
```bash
make deploy-gcp-local
```

**Option 3: Using deploy script**
```bash
./deploy.sh
```

### Manage Deployment
```bash
make logs            # View logs
make logs-follow     # Follow logs in real-time
make describe        # View service details
make url             # Get service URL
make delete          # Delete service
```

## 📋 Makefile Commands

Run `make help` to see all available commands:

**Development:**
- `make install` - Install dependencies
- `make init-db` - Initialize database
- `make dev` - Start development server
- `make start` - Start production server
- `make clean` - Clean generated files

**Docker:**
- `make docker-build` - Build Docker image
- `make docker-run` - Run container locally
- `make docker-test` - Test container
- `make docker-shell` - Open shell in container

**Google Cloud Run:**
- `make deploy-gcp` - Deploy with Cloud Build
- `make deploy-gcp-local` - Deploy with local build
- `make logs` - View logs
- `make describe` - Describe service
- `make delete` - Delete service

## 📁 Project Structure

```
cursor-rules/
├── src/
│   ├── server.js          # Express server
│   ├── init-db.js         # Database initialization
│   └── db.js              # SQLite connection
├── public/
│   ├── index.html         # Main interface
│   └── styles.css         # CSS styles
├── uploads/               # Uploaded files
├── data/
│   └── database.db        # SQLite database
└── package.json
```

## 🎨 Interface

The interface was inspired by the official Cursor Rules website, featuring:
- Modern and clean design
- Vibrant gradients
- Smooth animations
- Interactive cards
- Category filter system

## 📝 API Endpoints

- `GET /api/rules` - List all rules
- `GET /api/rules/search?q=term` - Search rules
- `GET /api/rules/tag/:tag` - Filter by tag
- `POST /api/rules/upload` - Upload new rule
- `GET /api/tags` - List all tags
- `GET /uploads/:filename` - Download file

## 🔧 Development

Run in development mode with hot reload:
```bash
bun run dev
```
