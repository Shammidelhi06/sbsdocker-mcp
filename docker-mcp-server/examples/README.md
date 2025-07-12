# Docker MCP Server Usage Examples

This directory contains example configurations and usage patterns for the Docker MCP Server.

## Container Management Examples

### Create and Run a Web Server

```json
{
  "name": "run_container",
  "arguments": {
    "name": "my-nginx",
    "image": "nginx:latest",
    "ports": {
      "80/tcp": "8080"
    },
    "env": ["NGINX_HOST=localhost"],
    "restart": "unless-stopped"
  }
}
```

### Run a Database Container

```json
{
  "name": "run_container",
  "arguments": {
    "name": "my-postgres",
    "image": "postgres:13",
    "env": [
      "POSTGRES_DB=myapp",
      "POSTGRES_USER=admin",
      "POSTGRES_PASSWORD=secret123"
    ],
    "ports": {
      "5432/tcp": "5432"
    },
    "volumes": [
      "postgres_data:/var/lib/postgresql/data"
    ],
    "restart": "unless-stopped"
  }
}
```

### Development Container with Volume Mounts

```json
{
  "name": "run_container",
  "arguments": {
    "name": "node-dev",
    "image": "node:18-alpine",
    "command": ["npm", "run", "dev"],
    "workingDir": "/app",
    "volumes": [
      "./:/app",
      "node_modules:/app/node_modules"
    ],
    "ports": {
      "3000/tcp": "3000"
    },
    "env": ["NODE_ENV=development"]
  }
}
```

## Image Management Examples

### Build Custom Image

```json
{
  "name": "build_image",
  "arguments": {
    "tag": "my-app:v1.0.0",
    "context": "./",
    "dockerfile": "Dockerfile",
    "buildArgs": {
      "NODE_ENV": "production",
      "API_URL": "https://api.example.com"
    }
  }
}
```

### Pull Specific Image Version

```json
{
  "name": "pull_image",
  "arguments": {
    "image": "redis",
    "tag": "6.2-alpine"
  }
}
```

## Network Management Examples

### Create Custom Network

```json
{
  "name": "create_network",
  "arguments": {
    "name": "app-network",
    "driver": "bridge"
  }
}
```

### List Networks with Filtering

```json
{
  "name": "list_networks",
  "arguments": {
    "filters": {
      "driver": ["bridge"]
    }
  }
}
```

## Volume Management Examples

### Create Named Volume

```json
{
  "name": "create_volume",
  "arguments": {
    "name": "app-data",
    "driver": "local"
  }
}
```

### List Volumes with Labels

```json
{
  "name": "list_volumes",
  "arguments": {
    "filters": {
      "label": ["environment=production"]
    }
  }
}
```

## Complex Workflows

### Full Application Stack

1. Create network:
```json
{
  "name": "create_network",
  "arguments": {
    "name": "app-stack"
  }
}
```

2. Create volumes:
```json
{
  "name": "create_volume",
  "arguments": {
    "name": "postgres-data"
  }
}
```

3. Run database:
```json
{
  "name": "run_container",
  "arguments": {
    "name": "app-db",
    "image": "postgres:13",
    "env": ["POSTGRES_DB=app", "POSTGRES_USER=user", "POSTGRES_PASSWORD=pass"],
    "volumes": ["postgres-data:/var/lib/postgresql/data"],
    "networks": ["app-stack"]
  }
}
```

4. Run application:
```json
{
  "name": "run_container",
  "arguments": {
    "name": "app-server",
    "image": "my-app:latest",
    "ports": {"3000/tcp": "3000"},
    "env": ["DATABASE_URL=postgresql://user:pass@app-db:5432/app"],
    "networks": ["app-stack"],
    "depends_on": ["app-db"]
  }
}
```

## Monitoring and Debugging

### Check Container Logs

```json
{
  "name": "fetch_container_logs",
  "arguments": {
    "id": "my-app",
    "tail": 50,
    "timestamps": true
  }
}
```

### List All Containers

```json
{
  "name": "list_containers",
  "arguments": {
    "all": true
  }
}
```

### Filter Running Containers

```json
{
  "name": "list_containers",
  "arguments": {
    "filters": {
      "status": ["running"]
    }
  }
}
```