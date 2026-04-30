'use client';
import dynamic from 'next/dynamic';

const GaugeComponent = dynamic(() => import('react-gauge-component'), { ssr: false });

interface Props {
  bpm: number;
  maxHR: number;
}

export function HRZoneGauge({ bpm, maxHR }: Props) {
  const max = maxHR > 0 ? maxHR : 200;
  const pct = max > 0 && bpm > 0 ? Math.min(100, (bpm / max) * 100) : 0;

  const zone =
    pct >= 90 ? { name: 'Z5 Max',       color: '#ef4444' } :
    pct >= 80 ? { name: 'Z4 Threshold', color: '#f97316' } :
    pct >= 70 ? { name: 'Z3 Cardio',    color: '#eab308' } :
    pct >= 60 ? { name: 'Z2 Fat Burn',  color: '#22c55e' } :
    pct >= 50 ? { name: 'Z1 Warm-up',   color: '#3b82f6' } :
                { name: 'Rest',          color: '#52525b' };

  return (
    <div className="flex flex-col h-full p-4 lg:p-6">
      <p className="text-[11px] uppercase tracking-widest font-semibold text-zinc-600">Heart Rate</p>

      <div className="flex-1 flex flex-col items-center justify-center -mt-2">
        <GaugeComponent
          value={bpm > 0 ? bpm : 0}
          minValue={0}
          maxValue={max}
          type="semicircle"
          arc={{
            width: 0.2,
            padding: 0.008,
            cornerRadius: 4,
            subArcs: [
              { limit: max * 0.50, color: '#3f3f46', showTick: false },
              { limit: max * 0.60, color: '#3b82f6', showTick: true },
              { limit: max * 0.70, color: '#22c55e', showTick: true },
              { limit: max * 0.80, color: '#eab308', showTick: true },
              { limit: max * 0.90, color: '#f97316', showTick: true },
              { limit: max,        color: '#ef4444', showTick: true },
            ],
          }}
          pointer={{
            color: '#18181b',
            length: 0.72,
            width: 12,
            elastic: true,
          }}
          labels={{
            valueLabel: {
              formatTextValue: () => '',
              style: {
                fill: 'transparent',
                fontSize: '1px',
                fontWeight: '400',
                textShadow: 'none',
              },
            },
            tickLabels: {
              type: 'outer',
              defaultTickValueConfig: {
                formatTextValue: (v: number) => String(Math.round(v)),
                style: { fontSize: '9px', fill: '#71717a' },
              },
              ticks: [
                { value: Math.round(max * 0.50) },
                { value: Math.round(max * 0.70) },
                { value: Math.round(max * 0.90) },
                { value: max },
              ],
            },
          }}
          style={{ width: '100%', maxWidth: 260 }}
        />

        <p
          className="text-5xl lg:text-6xl font-black tabular-nums leading-none mt-1"
          style={{ color: bpm > 0 ? zone.color : '#a1a1aa' }}
        >
          {bpm > 0 ? bpm : '—'}
        </p>

        {bpm > 0 && (
          <p
            className="text-[11px] font-semibold mt-1 tabular-nums"
            style={{ color: zone.color }}
          >
            {zone.name} · {pct.toFixed(0)}% max HR
          </p>
        )}
      </div>
    </div>
  );
}
