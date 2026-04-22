// Utilities for the Web Serial API
// https://developer.mozilla.org/en-US/docs/Web/API/Web_Serial_API

export type SerialPortLike = any; // Web Serial API types aren't in stock TS dom lib

/** True when Web Serial is available in this browser */
export function isSerialSupported(): boolean {
  return typeof navigator !== 'undefined' && 'serial' in navigator;
}

/** Return all previously-authorised ports */
export async function getAuthorizedPorts(): Promise<SerialPortLike[]> {
  if (!isSerialSupported()) return [];
  return (navigator as any).serial.getPorts();
}

/** Prompt the user to pick a port */
export async function requestPort(): Promise<SerialPortLike> {
  if (!isSerialSupported()) throw new Error('Web Serial not supported');
  return (navigator as any).serial.requestPort();
}

/** Open a port at the given baud rate */
export async function openPort(
  port: SerialPortLike,
  baudRate: number,
): Promise<void> {
  await port.open({ baudRate });
}

/**
 * Close a port gracefully.
 * Forgets the reader lock first to avoid InvalidStateError.
 */
export async function closePort(port: SerialPortLike): Promise<void> {
  try {
    await port.close();
  } catch {
    // already closed or never opened — safe to ignore
  }
}

/**
 * Async generator that yields complete newline-terminated lines from a port.
 * Pass an AbortSignal to stop reading.
 */
export async function* readLines(
  port: SerialPortLike,
  signal: AbortSignal,
): AsyncGenerator<string> {
  const decoder = new TextDecoderStream();
  const pipePromise = port.readable.pipeTo(decoder.writable, { signal });
  const reader = decoder.readable.getReader();

  let buffer = '';
  try {
    while (true) {
      if (signal.aborted) break;
      const { value, done } = await reader.read();
      if (done) break;
      buffer += value;
      const lines = buffer.split('\n');
      buffer = lines.pop() ?? '';
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed) yield trimmed;
      }
    }
  } finally {
    reader.releaseLock();
    // Let the pipe settle; ignore AbortError
    await pipePromise.catch(() => {});
  }
}
