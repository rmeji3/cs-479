'use client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Heart } from 'lucide-react';
import { cn } from '@/lib/utils';
import { SPO2_LOW, BPM_LOW, BPM_HIGH } from '@/lib/constants';
import type { SensorPacket } from '@/hooks/useSensorData';

interface Props {
  latest: SensorPacket | null;
}

function bpmColor(bpm: number) {
  if (bpm === 0) return 'text-zinc-500';
  if (bpm < BPM_LOW || bpm > BPM_HIGH) return 'text-red-400';
  if (bpm > 120) return 'text-orange-400';
  return 'text-emerald-400';
}

function spo2Color(spo2: number) {
  if (spo2 === 0) return 'text-zinc-500';
  if (spo2 < SPO2_LOW) return 'text-red-400';
  if (spo2 < 97) return 'text-yellow-400';
  return 'text-emerald-400';
}

export function HealthCard({ latest }: Props) {
  const bpm = latest?.bpm ?? 0;
  const spo2 = latest?.spo2 ?? 0;

  return (
    <Card className="bg-zinc-900 border-zinc-800">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold uppercase tracking-widest text-zinc-400 flex items-center gap-2">
          <Heart size={14} />
          Health Metrics
        </CardTitle>
      </CardHeader>
      <CardContent className="grid grid-cols-2 gap-6 py-2">
        {/* BPM */}
        <div className="text-center space-y-1">
          <p className={cn('text-4xl font-bold font-mono tabular-nums', bpmColor(bpm))}>
            {bpm === 0 ? '—' : bpm}
          </p>
          <p className="text-[11px] text-zinc-500 uppercase tracking-wider">BPM</p>
          <p className={cn('text-[10px]', bpmColor(bpm))}>
            {bpm === 0 ? 'No signal' : bpm < BPM_LOW ? 'Low' : bpm > BPM_HIGH ? 'High' : 'Normal'}
          </p>
        </div>

        {/* SpO2 */}
        <div className="text-center space-y-1">
          <p className={cn('text-4xl font-bold font-mono tabular-nums', spo2Color(spo2))}>
            {spo2 === 0 ? '—' : `${spo2}%`}
          </p>
          <p className="text-[11px] text-zinc-500 uppercase tracking-wider">SpO₂</p>
          <p className={cn('text-[10px]', spo2Color(spo2))}>
            {spo2 === 0 ? 'No signal' : spo2 < SPO2_LOW ? 'Low — seek care' : 'Normal'}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
