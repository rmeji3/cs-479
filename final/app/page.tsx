'use client';
import { useState, useEffect } from 'react';
import { Bike, PlugZap, Wifi } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useSerial } from '@/hooks/useSerial';
import { useSensorData } from '@/hooks/useSensorData';
import { BlindSpotRadar } from '@/components/BlindSpotRadar';
import { CrashModal } from '@/components/CrashModal';
import {
  BLIND_SPOT_THRESHOLD_MM,
  DISTANCE_DANGER_MM,
  DISTANCE_WARNING_MM,
  BPM_LOW,
  BPM_HIGH,
  SPO2_LOW,
  FALL_THRESHOLD,
} from '@/lib/constants';

// ── Metric tile (Zwift-style) ─────────────────────────
interface TileProps {
  label: string;
  value: string | number;
  unit?: string;
  valueColor?: string;
  dimBg?: boolean;       // subtle tinted background for alerts
}

function MetricTile({ label, value, unit, valueColor, dimBg }: TileProps) {
  return (
    <div className={cn(
      'flex flex-col justify-between p-4 lg:p-6 transition-colors duration-500',
      dimBg && 'bg-red-500/10',
    )}>
      <p className="text-[11px] uppercase tracking-widest font-semibold text-zinc-500">{label}</p>
      <div className="flex items-baseline gap-1.5 mt-2">
        <span className={cn(
          'text-5xl lg:text-6xl font-bold tabular-nums leading-none',
          valueColor ?? 'text-white',
        )}>
          {value}
        </span>
        {unit && (
          <span className="text-zinc-500 text-sm leading-none">{unit}</span>
        )}
      </div>
    </div>
  );
}

// ── Page ─────────────────────────────────────────────
export default function Home() {
  const serial = useSerial();
  const { latest, fallAlert, blindSpotAlert, packetCount } = useSensorData(serial.onLine);

  // Crash modal stays open until user dismisses (fallAlert auto-clears in hook, modal doesn't)
  const [crashOpen, setCrashOpen] = useState(false);
  useEffect(() => {
    if (fallAlert) setCrashOpen(true);
  }, [fallAlert]);

  // ── Derived values ──────────────────────────────────
  const dist      = latest?.dist      ?? -1;
  const bpm       = latest?.bpm       ?? 0;
  const spo2      = latest?.spo2      ?? 0;
  const accelMag  = latest?.accel_mag ?? 0;

  const distColor =
    dist === -1               ? 'text-zinc-600' :
    dist <= DISTANCE_DANGER_MM  ? 'text-red-400'    :
    dist <= DISTANCE_WARNING_MM ? 'text-orange-400' :
    dist <= BLIND_SPOT_THRESHOLD_MM ? 'text-yellow-400' : 'text-white';

  const bpmColor =
    bpm === 0                          ? 'text-zinc-600'  :
    bpm < BPM_LOW || bpm > BPM_HIGH    ? 'text-red-400'   :
    bpm > 120                          ? 'text-orange-400': 'text-white';

  const spo2Color =
    spo2 === 0       ? 'text-zinc-600'  :
    spo2 < SPO2_LOW  ? 'text-red-400'   :
    spo2 < 97        ? 'text-yellow-400': 'text-white';

  const impactColor =
    accelMag >= FALL_THRESHOLD ? 'text-red-400'    :
    accelMag >= 15             ? 'text-orange-400' :
    accelMag > 0               ? 'text-white'      : 'text-zinc-600';

  function fmtDist(d: number): string {
    if (d <= 0) return '—';
    return d >= 1000 ? (d / 1000).toFixed(1) : String(d);
  }
  const distUnit = dist > 0 ? (dist >= 1000 ? 'm' : 'mm') : undefined;

  return (
    <div className="h-screen bg-zinc-950 text-zinc-100 flex flex-col overflow-hidden select-none">

      {/* ── Header ───────────────────────────────────── */}
      <header className="flex items-center justify-between px-4 h-11 border-b border-zinc-800 shrink-0">
        <div className="flex items-center gap-2">
          <Bike size={16} className="text-blue-400" />
          <span className="text-sm font-bold tracking-tight">CycleWatch</span>
        </div>

        <div className="flex items-center gap-3">
          {serial.status === 'connected' ? (
            <div className="flex items-center gap-2.5">
              <span className="text-[11px] font-mono text-zinc-600">{packetCount} pkts</span>
              <div className="flex items-center gap-1 text-emerald-400 text-xs">
                <Wifi size={12} />
                <span>Connected</span>
              </div>
              <button
                onClick={serial.disconnect}
                className="text-[11px] text-zinc-600 hover:text-red-400 border border-zinc-800
                           hover:border-red-500/40 rounded px-2 py-0.5 transition-colors"
              >
                Disconnect
              </button>
            </div>
          ) : (
            <button
              onClick={serial.connect}
              className="flex items-center gap-1.5 text-xs text-zinc-400 hover:text-white
                         border border-zinc-700 hover:border-zinc-500 rounded-lg px-3 py-1 transition-colors"
            >
              <PlugZap size={12} />
              Connect Device
            </button>
          )}
        </div>
      </header>

      {/* ── Main ─────────────────────────────────────── */}
      <div className="flex flex-1 min-h-0">

        {/* Left: blind spot radar */}
        <div className="flex-1 min-w-0 border-r border-zinc-800">
          <BlindSpotRadar
            dist={dist}
            mic={latest?.mic ?? 0}
            blindSpotAlert={blindSpotAlert}
          />
        </div>

        {/* Right: 2×2 metric grid
            gap-px on a bg-zinc-800 container creates the 1px dividers between tiles */}
        <div className="w-[42%] grid grid-cols-2 grid-rows-2 gap-px bg-zinc-800 shrink-0">

          {/* Distance */}
          <div className={cn('bg-zinc-950', blindSpotAlert && 'bg-orange-500/10 transition-colors duration-500')}>
            <MetricTile
              label="Distance"
              value={fmtDist(dist)}
              unit={distUnit}
              valueColor={distColor}
            />
          </div>

          {/* Heart Rate */}
          <div className="bg-zinc-950">
            <MetricTile
              label="Heart Rate"
              value={bpm === 0 ? '—' : bpm}
              unit={bpm !== 0 ? 'bpm' : undefined}
              valueColor={bpmColor}
            />
          </div>

          {/* SpO₂ */}
          <div className="bg-zinc-950">
            <MetricTile
              label="Blood Oxygen"
              value={spo2 === 0 ? '—' : spo2}
              unit={spo2 !== 0 ? '%' : undefined}
              valueColor={spo2Color}
            />
          </div>

          {/* Impact */}
          <div className={cn('bg-zinc-950', accelMag >= FALL_THRESHOLD && 'bg-red-500/10 transition-colors duration-500')}>
            <MetricTile
              label="Impact"
              value={accelMag === 0 ? '—' : accelMag.toFixed(1)}
              unit={accelMag !== 0 ? 'm/s²' : undefined}
              valueColor={impactColor}
            />
          </div>
        </div>
      </div>

      {/* ── Footer ───────────────────────────────────── */}
      <footer className="h-8 flex items-center justify-between px-4 border-t border-zinc-800 shrink-0 text-[10px] text-zinc-700 font-mono">
        <span>
          AX {(latest?.ax ?? 0).toFixed(2)} ·
          AY {(latest?.ay ?? 0).toFixed(2)} ·
          AZ {(latest?.az ?? 0).toFixed(2)}
        </span>
        <span>
          GX {(latest?.gx ?? 0).toFixed(2)} ·
          GY {(latest?.gy ?? 0).toFixed(2)} ·
          GZ {(latest?.gz ?? 0).toFixed(2)}
        </span>
        <span className={cn(
          fallAlert      ? 'text-red-400 font-bold'    :
          blindSpotAlert ? 'text-orange-400 font-bold' : '',
        )}>
          {fallAlert ? '⚠ FALL ALERT' : blindSpotAlert ? '⚠ BLIND SPOT' : 'No alerts'}
        </span>
      </footer>

      {/* ── Crash modal ──────────────────────────────── */}
      <CrashModal open={crashOpen} onDismiss={() => setCrashOpen(false)} />
    </div>
  );
}
