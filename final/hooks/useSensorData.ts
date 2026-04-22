import { useState, useEffect, useRef, useCallback } from 'react';
import { CHART_HISTORY, FALL_THRESHOLD, BLIND_SPOT_THRESHOLD_MM } from '@/lib/constants';

export interface SensorPacket {
  // Blind spot
  dist: number;         // mm, -1 = timeout
  blind_spot: boolean;
  // IMU
  ax: number; ay: number; az: number;
  gx: number; gy: number; gz: number;
  accel_mag: number;
  fall: boolean;
  // Health
  spo2: number;
  bpm: number;
  // Mic
  mic: number;
  // Meta
  ts: number;
}

export interface ChartPoint {
  ts: number;
  dist: number;
  accel_mag: number;
  spo2: number;
  bpm: number;
  mic: number;
}

export interface SensorState {
  latest: SensorPacket | null;
  history: ChartPoint[];
  /** True while the fall alert should be shown */
  fallAlert: boolean;
  /** True while the blind spot alert should be shown */
  blindSpotAlert: boolean;
  /** Number of valid packets received since connect */
  packetCount: number;
}

const FALL_ALERT_DURATION_MS = 5000;
const BLIND_SPOT_ALERT_DURATION_MS = 2000;

export function useSensorData(
  onLine: (cb: (line: string) => void) => () => void,
): SensorState {
  const [latest, setLatest] = useState<SensorPacket | null>(null);
  const [history, setHistory] = useState<ChartPoint[]>([]);
  const [fallAlert, setFallAlert] = useState(false);
  const [blindSpotAlert, setBlindSpotAlert] = useState(false);
  const [packetCount, setPacketCount] = useState(0);

  const fallTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const blindTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handleLine = useCallback((line: string) => {
    let packet: SensorPacket;
    try {
      packet = JSON.parse(line) as SensorPacket;
    } catch {
      return; // skip non-JSON lines (e.g. boot messages)
    }

    setLatest(packet);
    setPacketCount(c => c + 1);

    setHistory(prev => {
      const point: ChartPoint = {
        ts: packet.ts,
        dist: packet.dist === -1 ? 0 : packet.dist,
        accel_mag: packet.accel_mag,
        spo2: packet.spo2,
        bpm: packet.bpm,
        mic: packet.mic,
      };
      const next = [...prev, point];
      return next.length > CHART_HISTORY ? next.slice(-CHART_HISTORY) : next;
    });

    // Fall alert
    if (packet.fall || packet.accel_mag >= FALL_THRESHOLD) {
      setFallAlert(true);
      if (fallTimerRef.current) clearTimeout(fallTimerRef.current);
      fallTimerRef.current = setTimeout(() => setFallAlert(false), FALL_ALERT_DURATION_MS);
    }

    // Blind spot alert
    if (packet.blind_spot) {
      setBlindSpotAlert(true);
      if (blindTimerRef.current) clearTimeout(blindTimerRef.current);
      blindTimerRef.current = setTimeout(
        () => setBlindSpotAlert(false),
        BLIND_SPOT_ALERT_DURATION_MS,
      );
    }
  }, []);

  useEffect(() => {
    const unsub = onLine(handleLine);
    return () => {
      unsub();
      if (fallTimerRef.current) clearTimeout(fallTimerRef.current);
      if (blindTimerRef.current) clearTimeout(blindTimerRef.current);
    };
  }, [onLine, handleLine]);

  return { latest, history, fallAlert, blindSpotAlert, packetCount };
}
