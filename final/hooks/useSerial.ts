import { useState, useCallback, useRef, useEffect } from 'react';
import {
  isSerialSupported,
  getAuthorizedPorts,
  requestPort,
  openPort,
  closePort,
  readLines,
  SerialPortLike,
} from '@/lib/serial';
import { BAUD_RATE } from '@/lib/constants';

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export interface UseSerialReturn {
  status: ConnectionStatus;
  port: SerialPortLike | null;
  pairedPorts: SerialPortLike[];
  supported: boolean;
  connect: () => Promise<void>;
  connectExisting: (p: SerialPortLike) => Promise<void>;
  disconnect: () => Promise<void>;
  refreshPairedPorts: () => Promise<void>;
  /** Subscribe to raw line strings from the serial stream */
  onLine: (cb: (line: string) => void) => () => void;
}

export function useSerial(): UseSerialReturn {
  const [status, setStatus] = useState<ConnectionStatus>('disconnected');
  const [port, setPort] = useState<SerialPortLike | null>(null);
  const [pairedPorts, setPairedPorts] = useState<SerialPortLike[]>([]);
  const supported = isSerialSupported();

  const abortRef = useRef<AbortController | null>(null);
  // Set of subscribers that want raw lines
  const listenersRef = useRef<Set<(line: string) => void>>(new Set());

  const onLine = useCallback((cb: (line: string) => void) => {
    listenersRef.current.add(cb);
    return () => listenersRef.current.delete(cb);
  }, []);

  const refreshPairedPorts = useCallback(async () => {
    const ports = await getAuthorizedPorts();
    setPairedPorts(ports);
  }, []);

  const startReading = useCallback(async (activePort: SerialPortLike) => {
    const controller = new AbortController();
    abortRef.current = controller;
    try {
      for await (const line of readLines(activePort, controller.signal)) {
        listenersRef.current.forEach(cb => cb(line));
      }
    } catch {
      // stream ended or aborted
    } finally {
      setStatus('disconnected');
      setPort(null);
    }
  }, []);

  const connectExisting = useCallback(async (p: SerialPortLike) => {
    if (status === 'connected') return;
    setStatus('connecting');
    try {
      await openPort(p, BAUD_RATE);
      setPort(p);
      setStatus('connected');
      startReading(p);
      await refreshPairedPorts();
    } catch (err) {
      console.error('Failed to open port:', err);
      setStatus('error');
    }
  }, [status, startReading, refreshPairedPorts]);

  const connect = useCallback(async () => {
    try {
      const p = await requestPort();
      await connectExisting(p);
    } catch (err) {
      console.error('Port request cancelled or failed:', err);
    }
  }, [connectExisting]);

  const disconnect = useCallback(async () => {
    abortRef.current?.abort();
    if (port) await closePort(port);
    setPort(null);
    setStatus('disconnected');
  }, [port]);

  // Listen for Web Serial connect/disconnect events
  useEffect(() => {
    if (!supported) return;
    const serial = (navigator as any).serial;
    const handler = () => refreshPairedPorts();
    serial.addEventListener('connect', handler);
    serial.addEventListener('disconnect', handler);
    refreshPairedPorts();
    return () => {
      serial.removeEventListener('connect', handler);
      serial.removeEventListener('disconnect', handler);
    };
  }, [supported, refreshPairedPorts]);

  return { status, port, pairedPorts, supported, connect, connectExisting, disconnect, refreshPairedPorts, onLine };
}
