# Docker MCP Server

A comprehensive Model Context Protocol (MCP) server for Docker management, providing tools for containers, images, networks, and volumes.

## Features

### Container Management
- `list_containers` - List all containers with filtering options
- `create_container` - Create a new container with configuration
- `run_container` - Create and start a container in one operation
- `recreate_container` - Recreate an existing container with same config
- `start_container` - Start a stopped container
- `fetch_container_logs` - Retrieve container logs with options
- `stop_container` - Stop a running container
- `remove_container` - Remove a container

### Image Management
- `list_images` - List Docker images with filtering
- `pull_image` - Pull images from registries
- `push_image` - Push images to registries
- `build_image` - Build images from Dockerfile
- `remove_image` - Remove images

### Network Management
- `list_networks` - List Docker networks
- `create_network` - Create new networks
- `remove_network` - Remove networks

### Volume Management
- `list_volumes` - List Docker volumes
- `create_volume` - Create new volumes
- `remove_volume` - Remove volumes

## Installation

```bash
npm install
npm run build
```

## Development

```bash
npm run dev
```

## Configuration

The server connects to Docker using the default Docker socket. Ensure Docker is running and accessible.

### Environment Variables

- `DOCKER_HOST` - Docker daemon socket (default: system default)
- `DOCKER_CERT_PATH` - Path to Docker certificates
- `DOCKER_TLS_VERIFY` - Enable TLS verification

## Usage Examples

### Container Operations

```json
{
  "name": "run_container",
  "arguments": {
    "name": "my-app",
    "image": "nginx:latest",
    "ports": {
      "80/tcp": "8080"
    },
    "env": ["ENV=production"],
    "restart": "unless-stopped"
  }
}
```

### Image Operations

```json
{
  "name": "build_image",
  "arguments": {
    "tag": "my-app:latest",
    "context": "./",
    "dockerfile": "Dockerfile",
    "buildArgs": {
      "NODE_ENV": "production"
    }
  }
}
```

### Network Operations

```json
{
  "name": "create_network",
  "arguments": {
    "name": "my-network",
    "driver": "bridge"
  }
}
```

### Volume Operations

```json
{
  "name": "create_volume",
  "arguments": {
    "name": "my-data",
    "driver": "local"
  }
}
```

## Error Handling

All operations include comprehensive error handling with descriptive messages. Failed operations return error responses with details about what went wrong.

## Security

- The server requires Docker daemon access
- Run with appropriate permissions for Docker operations
- Validate all inputs through Zod schemas
- No direct shell command execution

## License

MIT