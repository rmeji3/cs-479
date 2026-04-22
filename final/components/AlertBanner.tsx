'use client';
import { AlertTriangle, Eye } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Props {
  fallAlert: boolean;
  blindSpotAlert: boolean;
}

export function AlertBanner({ fallAlert, blindSpotAlert }: Props) {
  if (!fallAlert && !blindSpotAlert) return null;

  return (
    <div className="flex flex-col gap-2">
      {fallAlert && (
        <div className={cn(
          'flex items-center gap-3 px-4 py-3 rounded-xl border animate-pulse',
          'bg-red-500/20 border-red-500/50 text-red-300',
        )}>
          <AlertTriangle size={18} className="shrink-0" />
          <div>
            <p className="font-bold text-sm">FALL / IMPACT DETECTED</p>
            <p className="text-xs text-red-400">High acceleration event — check rider status</p>
          </div>
        </div>
      )}
      {blindSpotAlert && (
        <div className={cn(
          'flex items-center gap-3 px-4 py-3 rounded-xl border animate-pulse',
          'bg-orange-500/20 border-orange-500/50 text-orange-300',
        )}>
          <Eye size={18} className="shrink-0" />
          <div>
            <p className="font-bold text-sm">BLIND SPOT WARNING</p>
            <p className="text-xs text-orange-400">Object detected on the left — check mirror</p>
          </div>
        </div>
      )}
    </div>
  );
}
