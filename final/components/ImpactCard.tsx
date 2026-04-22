'use client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Activity } from 'lucide-react';
import { cn } from '@/lib/utils';
import { FALL_THRESHOLD } from '@/lib/constants';
import type { SensorPacket } from '@/hooks/useSensorData';

interface Props {
  latest: SensorPacket | null;
  fallAlert: boolean;
}

export function ImpactCard({ latest, fallAlert }: Props) {
  const mag = latest?.accel_mag ?? 0;
  const ax = latest?.ax ?? 0;
  const ay = latest?.ay ?? 0;
  const az = latest?.az ?? 0;

  const magPct = Math.min(100, (mag / 30) * 100);
  const magColor =
    mag >= FALL_THRESHOLD ? 'text-red-400' :
    mag >= 15 ? 'text-orange-400' :
    mag > 0 ? 'text-emerald-400' : 'text-zinc-500';

  return (
    <Card className={cn(
      'bg-zinc-900 border-zinc-800 transition-all',
      fallAlert && 'border-red-500/60 shadow-lg shadow-red-500/10',
    )}>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold uppercase tracking-widest text-zinc-400 flex items-center gap-2">
          <Activity size={14} />
          Impact / Motion
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Magnitude */}
        <div className="flex items-end justify-between">
          <div>
            <p className={cn('text-4xl font-bold font-mono tabular-nums', magColor)}>
              {mag === 0 ? '—' : mag.toFixed(1)}
            </p>
            <p className="text-[11px] text-zinc-500 uppercase tracking-wider">m/s² magnitude</p>
          </div>
          <span className={cn('text-xs px-2 py-1 rounded-full border font-mono',
            fallAlert
              ? 'bg-red-500/20 text-red-400 border-red-500/40'
              : 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20',
          )}>
            {fallAlert ? 'IMPACT' : 'NORMAL'}
          </span>
        </div>

        {/* Magnitude bar */}
        <div className="h-2 rounded-full bg-zinc-800 overflow-hidden">
          <div
            className={cn('h-full rounded-full transition-all duration-150', {
              'bg-emerald-500': mag < 15,
              'bg-orange-500': mag >= 15 && mag < FALL_THRESHOLD,
              'bg-red-500': mag >= FALL_THRESHOLD,
            })}
            style={{ width: `${magPct}%` }}
          />
        </div>

        {/* Raw axes */}
        <div className="grid grid-cols-3 gap-2 text-center">
          {[['X', ax], ['Y', ay], ['Z', az]].map(([axis, val]) => (
            <div key={String(axis)} className="bg-zinc-800 rounded-lg py-2">
              <p className="text-xs font-bold text-zinc-400">{axis}</p>
              <p className="text-sm font-mono text-zinc-200">{Number(val).toFixed(1)}</p>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
