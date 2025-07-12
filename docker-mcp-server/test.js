#!/usr/bin/env node

/**
 * Test script for Docker MCP Server
 * Run this to verify the server is working correctly
 */

const { spawn } = require('child_process');
const path = require('path');

// Test cases
const testCases = [
  {
    name: 'List containers',
    request: {
      jsonrpc: '2.0',
      id: 1,
      method: 'tools/call',
      params: {
        name: 'list_containers',
        arguments: { all: true }
      }
    }
  },
  {
    name: 'List images',
    request: {
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/call',
      params: {
        name: 'list_images',
        arguments: {}
      }
    }
  },
  {
    name: 'List networks',
    request: {
      jsonrpc: '2.0',
      id: 3,
      method: 'tools/call',
      params: {
        name: 'list_networks',
        arguments: {}
      }
    }
  },
  {
    name: 'List volumes',
    request: {
      jsonrpc: '2.0',
      id: 4,
      method: 'tools/call',
      params: {
        name: 'list_volumes',
        arguments: {}
      }
    }
  }
];

async function runTest() {
  console.log('🐳 Testing Docker MCP Server...\n');
  
  const serverPath = path.join(__dirname, 'dist', 'index.js');
  
  for (const testCase of testCases) {
    console.log(`Testing: ${testCase.name}`);
    
    try {
      const child = spawn('node', [serverPath], {
        stdio: ['pipe', 'pipe', 'pipe']
      });
      
      let output = '';
      
      child.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      child.stderr.on('data', (data) => {
        console.error(`stderr: ${data}`);
      });
      
      // Send initialize request first
      const initRequest = {
        jsonrpc: '2.0',
        id: 0,
        method: 'initialize',
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {},
          clientInfo: { name: 'test-client', version: '1.0.0' }
        }
      };
      
      child.stdin.write(JSON.stringify(initRequest) + '\n');
      
      // Wait a bit for initialization
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Send test request
      child.stdin.write(JSON.stringify(testCase.request) + '\n');
      child.stdin.end();
      
      await new Promise((resolve) => {
        child.on('close', (code) => {
          console.log(`✅ ${testCase.name} completed (exit code: ${code})`);
          if (output) {
            console.log('Response:', output.substring(0, 200) + '...\n');
          }
          resolve();
        });
      });
      
    } catch (error) {
      console.error(`❌ ${testCase.name} failed:`, error.message);
    }
  }
  
  console.log('🎉 Testing completed!');
}

if (require.main === module) {
  runTest().catch(console.error);
}

module.exports = { runTest };