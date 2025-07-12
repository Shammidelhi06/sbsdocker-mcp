const Docker = require('dockerode');

async function testDocker() {
  try {
    console.log('Testing Docker connection...');
    
    // Create Docker client
    const docker = new Docker({
      host: '127.0.0.1',
      port: 2375,
      protocol: 'http'
    });
    
    // Test connection by getting version
    const version = await docker.version();
    console.log('✅ Docker connected successfully!');
    console.log('Docker version:', version.Version);
    
    // Test listing containers
    const containers = await docker.listContainers({ all: true });
    console.log(`✅ Found ${containers.length} containers`);
    
    // Test listing images
    const images = await docker.listImages();
    console.log(`✅ Found ${images.length} images`);
    
    // Test listing networks
    const networks = await docker.listNetworks();
    console.log(`✅ Found ${networks.length} networks`);
    
    // Test listing volumes
    const volumes = await docker.listVolumes();
    console.log(`✅ Found ${volumes.Volumes ? volumes.Volumes.length : 0} volumes`);
    
    console.log('\n🎉 All Docker operations working!');
    
  } catch (error) {
    console.error('❌ Docker test failed:', error.message);
    
    // Try alternative connection
    try {
      console.log('\nTrying default Docker connection...');
      const docker2 = new Docker();
      const version2 = await docker2.version();
      console.log('✅ Default Docker connection works!');
      console.log('Docker version:', version2.Version);
    } catch (error2) {
      console.error('❌ Default Docker connection also failed:', error2.message);
      console.log('\n💡 Tips:');
      console.log('1. Make sure Docker is running');
      console.log('2. Check if SBSDocker is started');
      console.log('3. Verify DOCKER_HOST environment variable');
    }
  }
}

testDocker();