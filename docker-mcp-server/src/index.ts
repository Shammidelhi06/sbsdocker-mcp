#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import Docker from 'dockerode';
import { z } from 'zod';

// Initialize Docker client
const docker = new Docker();

// Tool schemas
const ListContainersSchema = z.object({
  all: z.boolean().optional().default(false),
  filters: z.record(z.string()).optional(),
});

const CreateContainerSchema = z.object({
  name: z.string(),
  image: z.string(),
  env: z.array(z.string()).optional(),
  ports: z.record(z.string()).optional(),
  volumes: z.array(z.string()).optional(),
  command: z.union([z.string(), z.array(z.string())]).optional(),
  workingDir: z.string().optional(),
  restart: z.string().optional(),
});

const RunContainerSchema = z.object({
  name: z.string(),
  image: z.string(),
  env: z.array(z.string()).optional(),
  ports: z.record(z.string()).optional(),
  volumes: z.array(z.string()).optional(),
  command: z.union([z.string(), z.array(z.string())]).optional(),
  workingDir: z.string().optional(),
  restart: z.string().optional(),
  detach: z.boolean().optional().default(true),
  autoRemove: z.boolean().optional().default(false),
});

const ContainerIdSchema = z.object({
  id: z.string(),
});

const ContainerLogsSchema = z.object({
  id: z.string(),
  tail: z.number().optional().default(100),
  follow: z.boolean().optional().default(false),
  timestamps: z.boolean().optional().default(false),
});

const ListImagesSchema = z.object({
  all: z.boolean().optional().default(false),
  filters: z.record(z.string()).optional(),
});

const PullImageSchema = z.object({
  image: z.string(),
  tag: z.string().optional().default('latest'),
});

const PushImageSchema = z.object({
  image: z.string(),
  tag: z.string().optional().default('latest'),
});

const BuildImageSchema = z.object({
  dockerfile: z.string().optional().default('Dockerfile'),
  context: z.string().optional().default('.'),
  tag: z.string(),
  buildArgs: z.record(z.string()).optional(),
});

const ImageIdSchema = z.object({
  id: z.string(),
  force: z.boolean().optional().default(false),
});

const ListNetworksSchema = z.object({
  filters: z.record(z.string()).optional(),
});

const CreateNetworkSchema = z.object({
  name: z.string(),
  driver: z.string().optional().default('bridge'),
  options: z.record(z.string()).optional(),
});

const NetworkIdSchema = z.object({
  id: z.string(),
});

const ListVolumesSchema = z.object({
  filters: z.record(z.string()).optional(),
});

const CreateVolumeSchema = z.object({
  name: z.string(),
  driver: z.string().optional().default('local'),
  options: z.record(z.string()).optional(),
});

const VolumeNameSchema = z.object({
  name: z.string(),
  force: z.boolean().optional().default(false),
});

// Helper functions
function parsePortBindings(ports: Record<string, string> | undefined): Record<string, any> {
  if (!ports) return {};
  
  const portBindings: Record<string, any> = {};
  const exposedPorts: Record<string, any> = {};
  
  Object.entries(ports).forEach(([containerPort, hostPort]) => {
    exposedPorts[containerPort] = {};
    portBindings[containerPort] = [{ HostPort: hostPort }];
  });
  
  return { portBindings, exposedPorts };
}

function parseVolumes(volumes: string[] | undefined): { binds: string[], volumes: Record<string, any> } {
  if (!volumes) return { binds: [], volumes: {} };
  
  const binds: string[] = [];
  const volumeObjects: Record<string, any> = {};
  
  volumes.forEach(volume => {
    if (volume.includes(':')) {
      binds.push(volume);
    } else {
      volumeObjects[volume] = {};
    }
  });
  
  return { binds, volumes: volumeObjects };
}
// Docker operation functions
async function listContainers(args: z.infer<typeof ListContainersSchema>) {
  try {
    const containers = await docker.listContainers({
      all: args.all,
      filters: args.filters ? JSON.stringify(args.filters) : undefined,
    });
    
    return containers.map(container => ({
      id: container.Id,
      names: container.Names,
      image: container.Image,
      command: container.Command,
      created: container.Created,
      status: container.Status,
      state: container.State,
      ports: container.Ports,
    }));
  } catch (error) {
    throw new Error(`Failed to list containers: ${error}`);
  }
}

async function createContainer(args: z.infer<typeof CreateContainerSchema>) {
  try {
    const { portBindings, exposedPorts } = parsePortBindings(args.ports);
    const { binds, volumes } = parseVolumes(args.volumes);
    
    const containerConfig = {
      Image: args.image,
      name: args.name,
      Env: args.env,
      Cmd: Array.isArray(args.command) ? args.command : args.command?.split(' '),
      WorkingDir: args.workingDir,
      ExposedPorts: exposedPorts,
      Volumes: volumes,
      HostConfig: {
        PortBindings: portBindings,
        Binds: binds,
        RestartPolicy: args.restart ? { Name: args.restart } : undefined,
      },
    };
    
    const container = await docker.createContainer(containerConfig);
    return {
      id: container.id,
      message: `Container ${args.name} created successfully`,
    };
  } catch (error) {
    throw new Error(`Failed to create container: ${error}`);
  }
}

async function runContainer(args: z.infer<typeof RunContainerSchema>) {
  try {
    const { portBindings, exposedPorts } = parsePortBindings(args.ports);
    const { binds, volumes } = parseVolumes(args.volumes);
    
    const containerConfig = {
      Image: args.image,
      name: args.name,
      Env: args.env,
      Cmd: Array.isArray(args.command) ? args.command : args.command?.split(' '),
      WorkingDir: args.workingDir,
      ExposedPorts: exposedPorts,
      Volumes: volumes,
      HostConfig: {
        PortBindings: portBindings,
        Binds: binds,
        RestartPolicy: args.restart ? { Name: args.restart } : undefined,
        AutoRemove: args.autoRemove,
      },
    };
    
    const container = await docker.createContainer(containerConfig);
    await container.start();
    
    return {
      id: container.id,
      message: `Container ${args.name} created and started successfully`,
    };
  } catch (error) {
    throw new Error(`Failed to run container: ${error}`);
  }
}

async function recreateContainer(args: z.infer<typeof ContainerIdSchema>) {
  try {
    const container = docker.getContainer(args.id);
    const containerInfo = await container.inspect();
    
    // Stop and remove existing container
    await container.stop();
    await container.remove();
    
    // Recreate with same configuration
    const config = containerInfo.Config;
    const hostConfig = containerInfo.HostConfig;
    
    const newContainer = await docker.createContainer({
      Image: config.Image,
      name: containerInfo.Name.replace('/', ''),
      Env: config.Env,
      Cmd: config.Cmd,
      WorkingDir: config.WorkingDir,
      ExposedPorts: config.ExposedPorts,
      Volumes: config.Volumes,
      HostConfig: hostConfig,
    });
    
    await newContainer.start();
    
    return {
      id: newContainer.id,
      message: `Container recreated successfully`,
    };
  } catch (error) {
    throw new Error(`Failed to recreate container: ${error}`);
  }
}

async function startContainer(args: z.infer<typeof ContainerIdSchema>) {
  try {
    const container = docker.getContainer(args.id);
    await container.start();
    return {
      id: args.id,
      message: 'Container started successfully',
    };
  } catch (error) {
    throw new Error(`Failed to start container: ${error}`);
  }
}

async function fetchContainerLogs(args: z.infer<typeof ContainerLogsSchema>) {
  try {
    const container = docker.getContainer(args.id);
    const logs = await container.logs({
      stdout: true,
      stderr: true,
      tail: args.tail,
      follow: false,
      timestamps: args.timestamps,
    } as any) as unknown as Buffer;
    
    return {
      id: args.id,
      logs: logs.toString(),
    };
  } catch (error) {
    throw new Error(`Failed to fetch container logs: ${error}`);
  }
}

async function stopContainer(args: z.infer<typeof ContainerIdSchema>) {
  try {
    const container = docker.getContainer(args.id);
    await container.stop();
    return {
      id: args.id,
      message: 'Container stopped successfully',
    };
  } catch (error) {
    throw new Error(`Failed to stop container: ${error}`);
  }
}

async function removeContainer(args: z.infer<typeof ContainerIdSchema>) {
  try {
    const container = docker.getContainer(args.id);
    await container.remove({ force: true });
    return {
      id: args.id,
      message: 'Container removed successfully',
    };
  } catch (error) {
    throw new Error(`Failed to remove container: ${error}`);
  }
}
// Image operations
async function listImages(args: z.infer<typeof ListImagesSchema>) {
  try {
    const images = await docker.listImages({
      all: args.all,
      filters: args.filters ? JSON.stringify(args.filters) : undefined,
    });
    
    return images.map(image => ({
      id: image.Id,
      repoTags: image.RepoTags,
      repoDigests: image.RepoDigests,
      created: image.Created,
      size: image.Size,
      virtualSize: image.VirtualSize,
    }));
  } catch (error) {
    throw new Error(`Failed to list images: ${error}`);
  }
}

async function pullImage(args: z.infer<typeof PullImageSchema>) {
  try {
    const imageTag = `${args.image}:${args.tag}`;
    const stream = await docker.pull(imageTag);
    
    return new Promise((resolve, reject) => {
      docker.modem.followProgress(stream, (err, res) => {
        if (err) {
          reject(new Error(`Failed to pull image: ${err}`));
        } else {
          resolve({
            image: imageTag,
            message: 'Image pulled successfully',
            details: res,
          });
        }
      });
    });
  } catch (error) {
    throw new Error(`Failed to pull image: ${error}`);
  }
}

async function pushImage(args: z.infer<typeof PushImageSchema>) {
  try {
    const imageTag = `${args.image}:${args.tag}`;
    const image = docker.getImage(imageTag);
    const stream = await image.push();
    
    return new Promise((resolve, reject) => {
      docker.modem.followProgress(stream, (err, res) => {
        if (err) {
          reject(new Error(`Failed to push image: ${err}`));
        } else {
          resolve({
            image: imageTag,
            message: 'Image pushed successfully',
            details: res,
          });
        }
      });
    });
  } catch (error) {
    throw new Error(`Failed to push image: ${error}`);
  }
}

async function buildImage(args: z.infer<typeof BuildImageSchema>) {
  try {
    const stream = await docker.buildImage(args.context, {
      dockerfile: args.dockerfile,
      t: args.tag,
      buildargs: args.buildArgs,
    });
    
    return new Promise((resolve, reject) => {
      docker.modem.followProgress(stream, (err, res) => {
        if (err) {
          reject(new Error(`Failed to build image: ${err}`));
        } else {
          resolve({
            tag: args.tag,
            message: 'Image built successfully',
            details: res,
          });
        }
      });
    });
  } catch (error) {
    throw new Error(`Failed to build image: ${error}`);
  }
}

async function removeImage(args: z.infer<typeof ImageIdSchema>) {
  try {
    const image = docker.getImage(args.id);
    await image.remove({ force: args.force });
    return {
      id: args.id,
      message: 'Image removed successfully',
    };
  } catch (error) {
    throw new Error(`Failed to remove image: ${error}`);
  }
}

// Network operations
async function listNetworks(args: z.infer<typeof ListNetworksSchema>) {
  try {
    const networks = await docker.listNetworks({
      filters: args.filters ? JSON.stringify(args.filters) : undefined,
    });
    
    return networks.map(network => ({
      id: network.Id,
      name: network.Name,
      driver: network.Driver,
      scope: network.Scope,
      created: network.Created,
      options: network.Options,
    }));
  } catch (error) {
    throw new Error(`Failed to list networks: ${error}`);
  }
}

async function createNetwork(args: z.infer<typeof CreateNetworkSchema>) {
  try {
    const network = await docker.createNetwork({
      Name: args.name,
      Driver: args.driver,
      Options: args.options,
    });
    
    return {
      id: network.id,
      name: args.name,
      message: 'Network created successfully',
    };
  } catch (error) {
    throw new Error(`Failed to create network: ${error}`);
  }
}

async function removeNetwork(args: z.infer<typeof NetworkIdSchema>) {
  try {
    const network = docker.getNetwork(args.id);
    await network.remove();
    return {
      id: args.id,
      message: 'Network removed successfully',
    };
  } catch (error) {
    throw new Error(`Failed to remove network: ${error}`);
  }
}

// Volume operations
async function listVolumes(args: z.infer<typeof ListVolumesSchema>) {
  try {
    const result = await docker.listVolumes({
      filters: args.filters ? JSON.stringify(args.filters) : undefined,
    });
    
    return {
      volumes: result.Volumes?.map(volume => ({
        name: volume.Name,
        driver: volume.Driver,
        mountpoint: volume.Mountpoint,
        created: (volume as any).CreatedAt || 'unknown',
        options: volume.Options,
        labels: volume.Labels,
      })) || [],
      warnings: result.Warnings,
    };
  } catch (error) {
    throw new Error(`Failed to list volumes: ${error}`);
  }
}

async function createVolume(args: z.infer<typeof CreateVolumeSchema>) {
  try {
    const volume = await docker.createVolume({
      Name: args.name,
      Driver: args.driver,
      DriverOpts: args.options,
    });
    
    return {
      name: volume.Name,
      driver: volume.Driver,
      mountpoint: volume.Mountpoint,
      message: 'Volume created successfully',
    };
  } catch (error) {
    throw new Error(`Failed to create volume: ${error}`);
  }
}

async function removeVolume(args: z.infer<typeof VolumeNameSchema>) {
  try {
    const volume = docker.getVolume(args.name);
    await volume.remove({ force: args.force });
    return {
      name: args.name,
      message: 'Volume removed successfully',
    };
  } catch (error) {
    throw new Error(`Failed to remove volume: ${error}`);
  }
}
// Tool definitions
const tools: Tool[] = [
  // Container tools
  {
    name: 'list_containers',
    description: 'List Docker containers with optional filtering',
    inputSchema: {
      type: 'object',
      properties: {
        all: { type: 'boolean', description: 'Show all containers (default shows only running)' },
        filters: { type: 'object', description: 'Filters to apply when listing containers' },
      },
    },
  },
  {
    name: 'create_container',
    description: 'Create a new Docker container',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Container name' },
        image: { type: 'string', description: 'Docker image to use' },
        env: { type: 'array', items: { type: 'string' }, description: 'Environment variables' },
        ports: { type: 'object', description: 'Port mappings (container:host)' },
        volumes: { type: 'array', items: { type: 'string' }, description: 'Volume mounts' },
        command: { oneOf: [{ type: 'string' }, { type: 'array', items: { type: 'string' } }], description: 'Command to run' },
        workingDir: { type: 'string', description: 'Working directory' },
        restart: { type: 'string', description: 'Restart policy' },
      },
      required: ['name', 'image'],
    },
  },
  {
    name: 'run_container',
    description: 'Create and start a Docker container',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Container name' },
        image: { type: 'string', description: 'Docker image to use' },
        env: { type: 'array', items: { type: 'string' }, description: 'Environment variables' },
        ports: { type: 'object', description: 'Port mappings (container:host)' },
        volumes: { type: 'array', items: { type: 'string' }, description: 'Volume mounts' },
        command: { oneOf: [{ type: 'string' }, { type: 'array', items: { type: 'string' } }], description: 'Command to run' },
        workingDir: { type: 'string', description: 'Working directory' },
        restart: { type: 'string', description: 'Restart policy' },
        detach: { type: 'boolean', description: 'Run in detached mode' },
        autoRemove: { type: 'boolean', description: 'Automatically remove container when it exits' },
      },
      required: ['name', 'image'],
    },
  },
  {
    name: 'recreate_container',
    description: 'Recreate an existing container with same configuration',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Container ID or name' },
      },
      required: ['id'],
    },
  },
  {
    name: 'start_container',
    description: 'Start a stopped container',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Container ID or name' },
      },
      required: ['id'],
    },
  },
  {
    name: 'fetch_container_logs',
    description: 'Fetch logs from a container',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Container ID or name' },
        tail: { type: 'number', description: 'Number of lines to show from end of logs' },
        follow: { type: 'boolean', description: 'Follow log output' },
        timestamps: { type: 'boolean', description: 'Show timestamps' },
      },
      required: ['id'],
    },
  },
  {
    name: 'stop_container',
    description: 'Stop a running container',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Container ID or name' },
      },
      required: ['id'],
    },
  },
  {
    name: 'remove_container',
    description: 'Remove a container',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Container ID or name' },
      },
      required: ['id'],
    },
  },
  // Image tools
  {
    name: 'list_images',
    description: 'List Docker images',
    inputSchema: {
      type: 'object',
      properties: {
        all: { type: 'boolean', description: 'Show all images (including intermediate)' },
        filters: { type: 'object', description: 'Filters to apply when listing images' },
      },
    },
  },
  {
    name: 'pull_image',
    description: 'Pull an image from a registry',
    inputSchema: {
      type: 'object',
      properties: {
        image: { type: 'string', description: 'Image name' },
        tag: { type: 'string', description: 'Image tag (default: latest)' },
      },
      required: ['image'],
    },
  },
  {
    name: 'push_image',
    description: 'Push an image to a registry',
    inputSchema: {
      type: 'object',
      properties: {
        image: { type: 'string', description: 'Image name' },
        tag: { type: 'string', description: 'Image tag (default: latest)' },
      },
      required: ['image'],
    },
  },
  {
    name: 'build_image',
    description: 'Build an image from a Dockerfile',
    inputSchema: {
      type: 'object',
      properties: {
        dockerfile: { type: 'string', description: 'Path to Dockerfile (default: Dockerfile)' },
        context: { type: 'string', description: 'Build context path (default: .)' },
        tag: { type: 'string', description: 'Image tag' },
        buildArgs: { type: 'object', description: 'Build arguments' },
      },
      required: ['tag'],
    },
  },
  {
    name: 'remove_image',
    description: 'Remove an image',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Image ID or name' },
        force: { type: 'boolean', description: 'Force removal' },
      },
      required: ['id'],
    },
  },
  // Network tools
  {
    name: 'list_networks',
    description: 'List Docker networks',
    inputSchema: {
      type: 'object',
      properties: {
        filters: { type: 'object', description: 'Filters to apply when listing networks' },
      },
    },
  },
  {
    name: 'create_network',
    description: 'Create a new Docker network',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Network name' },
        driver: { type: 'string', description: 'Network driver (default: bridge)' },
        options: { type: 'object', description: 'Driver options' },
      },
      required: ['name'],
    },
  },
  {
    name: 'remove_network',
    description: 'Remove a Docker network',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Network ID or name' },
      },
      required: ['id'],
    },
  },
  // Volume tools
  {
    name: 'list_volumes',
    description: 'List Docker volumes',
    inputSchema: {
      type: 'object',
      properties: {
        filters: { type: 'object', description: 'Filters to apply when listing volumes' },
      },
    },
  },
  {
    name: 'create_volume',
    description: 'Create a new Docker volume',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Volume name' },
        driver: { type: 'string', description: 'Volume driver (default: local)' },
        options: { type: 'object', description: 'Driver options' },
      },
      required: ['name'],
    },
  },
  {
    name: 'remove_volume',
    description: 'Remove a Docker volume',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Volume name' },
        force: { type: 'boolean', description: 'Force removal' },
      },
      required: ['name'],
    },
  },
];

// Server setup
const server = new Server(
  {
    name: 'docker-mcp-server',
    version: '1.0.0',
  }
);

// Tool handlers
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools,
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      // Container operations
      case 'list_containers':
        return { content: [{ type: 'text', text: JSON.stringify(await listContainers(ListContainersSchema.parse(args)), null, 2) }] };
      case 'create_container':
        return { content: [{ type: 'text', text: JSON.stringify(await createContainer(CreateContainerSchema.parse(args)), null, 2) }] };
      case 'run_container':
        return { content: [{ type: 'text', text: JSON.stringify(await runContainer(RunContainerSchema.parse(args)), null, 2) }] };
      case 'recreate_container':
        return { content: [{ type: 'text', text: JSON.stringify(await recreateContainer(ContainerIdSchema.parse(args)), null, 2) }] };
      case 'start_container':
        return { content: [{ type: 'text', text: JSON.stringify(await startContainer(ContainerIdSchema.parse(args)), null, 2) }] };
      case 'fetch_container_logs':
        return { content: [{ type: 'text', text: JSON.stringify(await fetchContainerLogs(ContainerLogsSchema.parse(args)), null, 2) }] };
      case 'stop_container':
        return { content: [{ type: 'text', text: JSON.stringify(await stopContainer(ContainerIdSchema.parse(args)), null, 2) }] };
      case 'remove_container':
        return { content: [{ type: 'text', text: JSON.stringify(await removeContainer(ContainerIdSchema.parse(args)), null, 2) }] };
      
      // Image operations
      case 'list_images':
        return { content: [{ type: 'text', text: JSON.stringify(await listImages(ListImagesSchema.parse(args)), null, 2) }] };
      case 'pull_image':
        return { content: [{ type: 'text', text: JSON.stringify(await pullImage(PullImageSchema.parse(args)), null, 2) }] };
      case 'push_image':
        return { content: [{ type: 'text', text: JSON.stringify(await pushImage(PushImageSchema.parse(args)), null, 2) }] };
      case 'build_image':
        return { content: [{ type: 'text', text: JSON.stringify(await buildImage(BuildImageSchema.parse(args)), null, 2) }] };
      case 'remove_image':
        return { content: [{ type: 'text', text: JSON.stringify(await removeImage(ImageIdSchema.parse(args)), null, 2) }] };
      
      // Network operations
      case 'list_networks':
        return { content: [{ type: 'text', text: JSON.stringify(await listNetworks(ListNetworksSchema.parse(args)), null, 2) }] };
      case 'create_network':
        return { content: [{ type: 'text', text: JSON.stringify(await createNetwork(CreateNetworkSchema.parse(args)), null, 2) }] };
      case 'remove_network':
        return { content: [{ type: 'text', text: JSON.stringify(await removeNetwork(NetworkIdSchema.parse(args)), null, 2) }] };
      
      // Volume operations
      case 'list_volumes':
        return { content: [{ type: 'text', text: JSON.stringify(await listVolumes(ListVolumesSchema.parse(args)), null, 2) }] };
      case 'create_volume':
        return { content: [{ type: 'text', text: JSON.stringify(await createVolume(CreateVolumeSchema.parse(args)), null, 2) }] };
      case 'remove_volume':
        return { content: [{ type: 'text', text: JSON.stringify(await removeVolume(VolumeNameSchema.parse(args)), null, 2) }] };

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{ type: 'text', text: `Error: ${error instanceof Error ? error.message : String(error)}` }],
      isError: true,
    };
  }
});

// Start the server
async function runServer() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Docker MCP Server running on stdio');
}

runServer().catch((error) => {
  console.error('Failed to run server:', error);
  process.exit(1);
});
