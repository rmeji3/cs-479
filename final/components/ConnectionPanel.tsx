'use client';
import { Bluetooth, BluetoothOff, RefreshCw, Plug } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { UseSerialReturn, ConnectionStatus } from '@/hooks/useSerial';

const STATUS_STYLES: Record<ConnectionStatus, string> = {
  connected: 'bg-emerald-100 text-emerald-700 border-emerald-300',
  connecting: 'bg-yellow-100 text-yellow-700 border-yellow-300',
  disconnected: 'bg-zinc-200 text-zinc-700 border-zinc-300',
  error: 'bg-red-100 text-red-700 border-red-300',
};

interface Props {
  serial: UseSerialReturn;
  packetCount: number;
}

export function ConnectionPanel({ serial, packetCount }: Props) {
  const { status, port, pairedPorts, supported, connect, connectExisting, disconnect, refreshPairedPorts } = serial;

  if (!supported) {
    return (
      <Card className="border-red-300/30 bg-red-100/50">
        <CardContent className="pt-4 text-sm text-red-700">
          Web Serial API not supported. Use Chrome or Edge with HTTPS.
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-white border-zinc-200">
      <CardHeader className="pb-3">
        <CardTitle className="text-sm font-semibold uppercase tracking-widest text-zinc-600 flex items-center gap-2">
          <Bluetooth size={14} />
          Connection
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Status row */}
        <div className="flex items-center justify-between">
          <span className={`text-xs px-2 py-1 rounded-full border font-mono ${STATUS_STYLES[status]}`}>
            {status.toUpperCase()}
          </span>
          {status === 'connected' && (
            <span className="text-xs text-zinc-600 font-mono">{packetCount} packets</span>
          )}
        </div>

        {/* Action buttons */}
        <div className="flex flex-col gap-2">
          {status !== 'connected' ? (
            <Button onClick={connect} size="sm" className="w-full bg-blue-600 hover:bg-blue-700 text-white">
              <Plug size={13} className="mr-1.5" />
              Connect Device
            </Button>
          ) : (
            <Button onClick={disconnect} size="sm" variant="destructive" className="w-full">
              <BluetoothOff size={13} className="mr-1.5" />
              Disconnect
            </Button>
          )}
          <Button onClick={refreshPairedPorts} size="sm" variant="outline" className="w-full border-zinc-300 text-zinc-600 hover:text-zinc-900">
            <RefreshCw size={12} className="mr-1.5" />
            Refresh Paired
          </Button>
        </div>

        {/* Paired ports list */}
        {pairedPorts.length > 0 && (
          <div className="space-y-1.5">
            <p className="text-xs text-zinc-500 uppercase tracking-wider">Paired Devices</p>
            {pairedPorts.map((p, i) => (
              <div key={i} className="flex items-center justify-between px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700">
                <span className="text-xs font-mono text-zinc-300">Port {i + 1}</span>
                {port === p ? (
                  <Badge className="text-[10px] bg-emerald-500/20 text-emerald-400 border-emerald-500/30">ACTIVE</Badge>
                ) : (
                  <Button
                    size="sm"
                    variant="ghost"
                    disabled={status === 'connected'}
                    onClick={() => connectExisting(p)}
                    className="h-6 text-xs text-zinc-400 hover:text-zinc-100"
                  >
                    Connect
                  </Button>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
