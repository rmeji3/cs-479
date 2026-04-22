'use client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Eye } from 'lucide-react';
import { cn } from '@/lib/utils';
import { BLIND_SPOT_THRESHOLD_MM, DISTANCE_DANGER_MM, DISTANCE_WARNING_MM } from '@/lib/constants';
import type { SensorPacket } from '@/hooks/useSensorData';

interface Props {
  latest: SensorPacket | null;
  blindSpotAlert: boolean;
}

function distanceColor(dist: number, timeout: boolean): string {
  if (timeout || dist <= 0) return 'text-zinc-500';
  if (dist <= DISTANCE_DANGER_MM) return 'text-red-400';
  if (dist <= DISTANCE_WARNING_MM) return 'text-orange-400';
  if (dist <= BLIND_SPOT_THRESHOLD_MM) return 'text-yellow-400';
  return 'text-emerald-400';
}

function distanceLabel(dist: number, timeout: boolean): string {
  if (timeout || dist <= 0) return 'No reading';
  if (dist <= DISTANCE_DANGER_MM) return 'DANGER — very close';
  if (dist <= DISTANCE_WARNING_MM) return 'WARNING — approaching';
  if (dist <= BLIND_SPOT_THRESHOLD_MM) return 'Caution — in range';
  return 'Clear';
}

export function BlindSpotCard({ latest, blindSpotAlert }: Props) {
  const timeout = !latest || latest.dist === -1;
  const dist = latest?.dist ?? 0;
  const mic = latest?.mic ?? 0;
  const color = distanceColor(dist, timeout);

  return (
    <Card className={cn(
      'bg-zinc-900 border-zinc-800 transition-all',
      blindSpotAlert && 'border-orange-500/60 shadow-lg shadow-orange-500/10',
    )}>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold uppercase tracking-widest text-zinc-400 flex items-center gap-2">
          <Eye size={14} />
          Left Blind Spot
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Distance readout */}
        <div className="text-center py-2">
          <p className={cn('text-5xl font-bold font-mono tabular-nums', color)}>
            {timeout ? '—' : dist >= 1000 ? `${(dist / 1000).toFixed(1)}m` : `${dist}mm`}
          </p>
          <p className={cn('text-xs mt-1', color)}>{distanceLabel(dist, timeout)}</p>
        </div>

        {/* Distance bar */}
        <div className="space-y-1">
          <div className="flex justify-between text-[10px] text-zinc-600">
            <span>0</span>
            <span>500mm</span>
            <span>1m</span>
            <span>1.5m+</span>
          </div>
          <div className="h-2 rounded-full bg-zinc-800 overflow-hidden">
            <div
              className={cn('h-full rounded-full transition-all duration-200', {
                'bg-emerald-500': !timeout && dist > DISTANCE_WARNING_MM,
                'bg-yellow-500': !timeout && dist > DISTANCE_DANGER_MM && dist <= DISTANCE_WARNING_MM,
                'bg-red-500': !timeout && dist <= DISTANCE_DANGER_MM,
                'bg-zinc-700': timeout || dist <= 0,
              })}
              style={{ width: timeout ? '0%' : `${Math.min(100, (dist / BLIND_SPOT_THRESHOLD_MM) * 100)}%` }}
            />
          </div>
        </div>

        {/* Mic */}
        <div className="flex items-center justify-between text-xs text-zinc-500">
          <span>Ambient sound</span>
          <span className={cn('font-mono', mic > 800 ? 'text-yellow-400' : 'text-zinc-400')}>
            {mic} <span className="text-zinc-600">/ 4095</span>
          </span>
        </div>
        <div className="h-1.5 rounded-full bg-zinc-800 overflow-hidden">
          <div
            className="h-full rounded-full bg-indigo-500 transition-all duration-200"
            style={{ width: `${Math.min(100, (mic / 4095) * 100)}%` }}
          />
        </div>
      </CardContent>
    </Card>
  );
}
