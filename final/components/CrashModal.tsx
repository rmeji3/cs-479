'use client';
import { useEffect, useRef, useState, useCallback } from 'react';
import { AlertTriangle, Phone, ShieldCheck } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Props {
  open: boolean;
  onDismiss: () => void;
  emergencyName?: string;
  emergencyPhone?: string;
}

const HOLD_MS      = 2000; // ms user must hold button to dismiss
const COUNTDOWN_S  = 10;   // seconds before contacting emergency contact

export function CrashModal({ open, onDismiss, emergencyName, emergencyPhone }: Props) {
  const [countdown,    setCountdown]    = useState(COUNTDOWN_S);
  const [holdProgress, setHoldProgress] = useState(0);   // 0–100
  const [contacted,    setContacted]    = useState(false);

  const countdownRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const holdRef      = useRef<ReturnType<typeof setInterval> | null>(null);
  const holdStart    = useRef(0);

  // Reset + start countdown whenever modal opens
  useEffect(() => {
    if (!open) return;

    setCountdown(COUNTDOWN_S);
    setHoldProgress(0);
    setContacted(false);

    countdownRef.current = setInterval(() => {
      setCountdown(c => {
        if (c <= 1) {
          clearInterval(countdownRef.current!);
          setContacted(true);
          // Trigger Twilio call if emergency contact is configured
          if (emergencyPhone) {
            fetch('/api/emergency-call', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ to: emergencyPhone, contactName: emergencyName }),
            }).catch(err => console.error('[CrashModal] Failed to call emergency contact:', err));
          }
          return 0;
        }
        return c - 1;
      });
    }, 1000);

    return () => {
      clearInterval(countdownRef.current!);
      clearInterval(holdRef.current!);
    };
  }, [open]);

  // Hold-to-dismiss mechanics
  const startHold = useCallback(() => {
    holdStart.current = Date.now();
    holdRef.current = setInterval(() => {
      const p = Math.min(100, ((Date.now() - holdStart.current) / HOLD_MS) * 100);
      setHoldProgress(p);
      if (p >= 100) {
        clearInterval(holdRef.current!);
        onDismiss();
      }
    }, 30);
  }, [onDismiss]);

  const stopHold = useCallback(() => {
    clearInterval(holdRef.current!);
    setHoldProgress(0);
  }, []);

  if (!open) return null;

  // SVG progress ring for hold button
  const r    = 44;
  const circ = 2 * Math.PI * r;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/95 backdrop-blur-sm">
      {contacted ? (
        /* ── Emergency contacted screen ────────────── */
        <div className="text-center space-y-6 px-8 max-w-sm w-full">
          <div className="w-20 h-20 rounded-full bg-green-500/20 border-2 border-green-500/40
                          flex items-center justify-center mx-auto">
            <Phone size={36} className="text-green-400 animate-pulse" />
          </div>
          <div>
            <p className="text-2xl font-black text-white">Contacting Emergency Contact</p>
            <p className="text-zinc-400 text-sm mt-2">
            {emergencyPhone
              ? `Calling ${emergencyName || emergencyPhone}…`
              : 'No emergency contact set. Add one in Settings.'}
          </p>
          </div>
          <button
            onClick={onDismiss}
            className="text-xs text-zinc-600 underline underline-offset-4 hover:text-zinc-400 transition-colors"
          >
            I'm OK — dismiss
          </button>
        </div>
      ) : (
        /* ── Hold-to-dismiss countdown screen ──────── */
        <div className="text-center space-y-8 max-w-xs w-full px-6">
          {/* Icon + title */}
          <div className="space-y-4">
            <div className="w-20 h-20 rounded-full bg-red-500/20 border-2 border-red-500/50
                            flex items-center justify-center mx-auto">
              <AlertTriangle size={36} className="text-red-400" />
            </div>
            <div>
              <h1 className="text-3xl font-black text-white tracking-tight">CRASH DETECTED</h1>
              <p className="text-zinc-400 text-sm mt-1">
                Emergency contact will be notified in
              </p>
            </div>
          </div>

          {/* Countdown number */}
          <div
            className={cn(
              'text-9xl font-black font-mono tabular-nums leading-none',
              countdown <= 3 ? 'text-red-400 animate-pulse' : 'text-white',
            )}
          >
            {countdown}
          </div>

          {/* Hold button with SVG progress ring */}
          <div className="flex flex-col items-center gap-3">
            <div
              className="relative w-24 h-24 select-none touch-none cursor-pointer"
              onPointerDown={startHold}
              onPointerUp={stopHold}
              onPointerLeave={stopHold}
              onPointerCancel={stopHold}
            >
              {/* Progress ring */}
              <svg
                className="absolute inset-0 -rotate-90"
                width="96" height="96" viewBox="0 0 96 96"
              >
                {/* Track */}
                <circle cx="48" cy="48" r={r} fill="none" stroke="#27272a" strokeWidth="7" />
                {/* Fill */}
                <circle
                  cx="48" cy="48" r={r}
                  fill="none"
                  stroke="#22c55e"
                  strokeWidth="7"
                  strokeLinecap="round"
                  strokeDasharray={circ}
                  strokeDashoffset={circ * (1 - holdProgress / 100)}
                  style={{ transition: 'stroke-dashoffset 30ms linear' }}
                />
              </svg>

              {/* Center icon */}
              <div className="absolute inset-2 rounded-full bg-zinc-800 border border-zinc-700
                              flex items-center justify-center pointer-events-none">
                <ShieldCheck size={24} className="text-emerald-400" />
              </div>
            </div>

            <p className="text-xs text-zinc-500">Hold to confirm you're OK</p>
          </div>
        </div>
      )}
    </div>
  );
}
