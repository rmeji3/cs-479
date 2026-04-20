'use client';
import { useState, useEffect } from 'react';

export default function Home() {
  const [port, setPort] = useState<any>(null);
  const [ports, setPorts] = useState<any[]>([]);
  const [receivedData, setReceivedData] = useState<string[]>([]);

  // Function to refresh the list of authorized ports
  async function refreshPorts() {
    if ('serial' in navigator) {
      const authorizedPorts = await (navigator as any).serial.getPorts();
      setPorts(authorizedPorts);
    }
  }

  // 1. Request a port and open it
  async function connectNewPort() {
    try {
      // Prompt user to select a serial port
      const serialNavigator = navigator as any;
      const newPort = await serialNavigator.serial.requestPort();
      await openPort(newPort);
      await refreshPorts();
    } catch (err) {
      console.error("Connection failed:", err);
    }
  }

  async function openPort(selectedPort: any) {
    try {
      await selectedPort.open({ baudRate: 115200 });
      setPort(selectedPort);
      console.log("Connected to serial port!");

      // Start reading in the background
      readFromPort(selectedPort);
    } catch (err) {
      console.error("Failed to open port:", err);
    }
  }

  async function readFromPort(selectedPort: any) {
    const textDecoder = new TextDecoder();
    while (selectedPort.readable) {
      const reader = selectedPort.readable.getReader();
      try {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
          const decoded = textDecoder.decode(value);
          setReceivedData(prev => [...prev.slice(-19), decoded]); // Keep last 20 messages
          console.log(decoded);
        }
      } catch (error) {
        console.error("Read error:", error);
        break;
      } finally {
        reader.releaseLock();
      }
    }
    setPort(null);
  }

  useEffect(() => {
    refreshPorts();
    
    // Listen for disconnects
    const handleDisconnect = () => refreshPorts();
    if ('serial' in navigator) {
      (navigator as any).serial.addEventListener('disconnect', handleDisconnect);
      (navigator as any).serial.addEventListener('connect', handleDisconnect);
    }
    
    return () => {
      if ('serial' in navigator) {
        (navigator as any).serial.removeEventListener('disconnect', handleDisconnect);
        (navigator as any).serial.removeEventListener('connect', handleDisconnect);
      }
    };
  }, []);

  return (
    <div className="flex flex-col min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-zinc-900 p-8 text-zinc-900 dark:text-zinc-100">
      <div className="max-w-md w-full bg-white dark:bg-zinc-800 rounded-xl shadow-lg p-6 border border-zinc-200 dark:border-zinc-700">
        <h1 className="text-2xl font-bold mb-6 text-center">Arduino Controller</h1>
        
        <div className="space-y-4">
          <div className="flex flex-col gap-2">
            <button 
              onClick={connectNewPort}
              className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
            >
              Connect New Device
            </button>
            <button 
              onClick={refreshPorts}
              className="w-full py-2 px-4 bg-zinc-200 dark:bg-zinc-700 hover:bg-zinc-300 dark:hover:bg-zinc-600 rounded-lg font-medium transition-colors text-sm"
            >
              Refresh Paired Devices
            </button>
          </div>

          <div className="mt-6">
            <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-500 mb-3">Paired Devices ({ports.length})</h2>
            <div className="space-y-2 max-h-40 overflow-y-auto">
              {ports.length === 0 ? (
                <p className="text-zinc-400 italic text-sm">No paired devices found.</p>
              ) : (
                ports.map((p, i) => (
                  <div key={i} className="flex items-center justify-between p-3 bg-zinc-100 dark:bg-zinc-700/50 rounded-lg border border-zinc-200 dark:border-zinc-700">
                    <span className="text-sm font-mono truncate mr-2">Port {i + 1}</span>
                    {port === p ? (
                      <span className="text-xs bg-green-500/20 text-green-600 dark:text-green-400 px-2 py-1 rounded-full font-bold">ACTIVE</span>
                    ) : (
                      <button 
                        disabled={!!port}
                        onClick={() => openPort(p)}
                        className="text-xs bg-zinc-200 dark:bg-zinc-600 hover:bg-zinc-300 dark:hover:bg-zinc-500 px-3 py-1 rounded-full transition-colors disabled:opacity-50"
                      >
                        {port ? 'Wait' : 'Connect'}
                      </button>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>

          {port && (
            <div className="mt-6 border-t border-zinc-200 dark:border-zinc-700 pt-6">
              <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-500 mb-3">Live Feed</h2>
              <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-3 h-48 overflow-y-auto font-mono text-xs text-white">
                {receivedData.length === 0 ? (
                  <span className="text-zinc-600">Waiting for data...</span>
                ) : (
                  receivedData.map((line, i) => (
                    <div key={i} className="whitespace-pre-wrap">{line}</div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
