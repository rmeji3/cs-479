'use client';
import { cn } from '@/lib/utils';
import {
  BLIND_SPOT_THRESHOLD_MM,
  DISTANCE_DANGER_MM,
  DISTANCE_WARNING_MM,
} from '@/lib/constants';

interface Props {
  dist: number;        // mm, -1 = timeout
  mic: number;         // 0–4095 ADC peak
  blindSpotAlert: boolean;
}

//  Radar geometry 
// Bike sits at the right edge; the radar sweeps left.
const CX = 370;   // px — bike x position (right side)
const CY = 180;   // px — vertical center
const MAX_R = 310; // px — maps to BLIND_SPOT_THRESHOLD_MM

const dangerR  = (DISTANCE_DANGER_MM  / BLIND_SPOT_THRESHOLD_MM) * MAX_R; 
const warningR = (DISTANCE_WARNING_MM / BLIND_SPOT_THRESHOLD_MM) * MAX_R; 

function toX(distMm: number) {
  return CX - (distMm / BLIND_SPOT_THRESHOLD_MM) * MAX_R;
}

/** Left semicircle filled sector */
function sector(r: number) {
  return `M ${CX} ${CY - r} A ${r} ${r} 0 0 0 ${CX} ${CY + r} L ${CX} ${CY} Z`;
}

/** Left semicircle arc only (no fill) */
function arc(r: number) {
  return `M ${CX} ${CY - r} A ${r} ${r} 0 0 0 ${CX} ${CY + r}`;
}

export function BlindSpotRadar({ dist, mic, blindSpotAlert }: Props) {
  const hasObj = dist > 0 && dist !== -1 && dist <= BLIND_SPOT_THRESHOLD_MM;
  const objX   = hasObj ? toX(dist) : CX;

  const objColor =
    !hasObj              ? '#eab308' :
    dist <= DISTANCE_DANGER_MM  ? '#ef4444' :
    dist <= DISTANCE_WARNING_MM ? '#f97316' :
                                  '#eab308';

  return (
    <div className="w-full h-full flex flex-col bg-white">
      {/*  Radar SVG  */}
      <div className="flex-1 relative overflow-hidden">
        <svg
          viewBox="0 0 400 360"
          className="w-full h-full"
          preserveAspectRatio="xMidYMid meet"
        >
          <defs>
            {/* Clip to a horizontal band — arcs that extend top/bottom are hidden,
                leaving a focused radar-strip feel */}
            <clipPath id="radarBand">
              <rect x="0" y="48" width="400" height="264" />
            </clipPath>
          </defs>

          <rect width="400" height="360" fill="#ffffff" />

          {/* Subtle lane guide lines */}
          <line x1="170" y1="0" x2="170" y2="360" stroke="#e4e4e7" strokeWidth="2" strokeDasharray="10 8" />
          <line x1="340" y1="0" x2="340" y2="360" stroke="#e4e4e7" strokeWidth="2" strokeDasharray="10 8" />

          {/* ── Zone fills + ring arcs (clipped) ── */}
          <g clipPath="url(#radarBand)">
            <path d={sector(MAX_R)}   fill="rgba(234,179,8,0.04)" />
            <path d={sector(warningR)} fill="rgba(249,115,22,0.07)" />
            <path d={sector(dangerR)}  fill="rgba(239,68,68,0.10)" />

            <path d={arc(MAX_R)}   fill="none" stroke="rgba(234,179,8,0.28)"   strokeWidth="1.5" />
            <path d={arc(warningR)} fill="none" stroke="rgba(249,115,22,0.32)" strokeWidth="1.5" />
            <path d={arc(dangerR)}  fill="none" stroke="rgba(239,68,68,0.38)"  strokeWidth="1.5" />
          </g>

          {/* Horizontal center ray */}
          <line
            x1={CX - MAX_R - 10} y1={CY}
            x2={CX}              y2={CY}
            stroke="#d4d4d8" strokeWidth="1" strokeDasharray="4 4"
          />

          {/* Zone labels */}
          <text x={CX - dangerR / 2}                     y={CY - 12} textAnchor="middle" fontSize="8" fill="rgba(239,68,68,0.55)"  fontFamily="monospace">20 in</text>
          <text x={CX - (dangerR + warningR) / 2}        y={CY - 12} textAnchor="middle" fontSize="8" fill="rgba(249,115,22,0.55)" fontFamily="monospace">3.3 ft</text>
          <text x={CX - (warningR + MAX_R) / 2}          y={CY - 12} textAnchor="middle" fontSize="8" fill="rgba(234,179,8,0.55)"  fontFamily="monospace">5 ft</text>

          {/*  Object indicator  */}
          {hasObj && (
            <>
              <line
                x1={CX} y1={CY} x2={objX} y2={CY}
                stroke={objColor} strokeWidth="1.5" strokeDasharray="3 3" opacity="0.5"
              />
              <circle cx={objX} cy={CY} r={10} fill={objColor} opacity="0.9" />
            </>
          )}

          {/*  Rider icon  */}
          <circle cx={CX} cy={CY} r="26" fill="#1d4ed8" opacity="0.95" />
          <circle cx={CX} cy={CY} r="26" fill="none" stroke="#60a5fa" strokeWidth="1.5" opacity="0.6" />
          {/* Lucide "Bike" icon paths (24×24 viewBox) scaled + centred */}
          <g transform={`translate(${CX}, ${CY}) rotate(-45) translate(-14, -14) scale(1.17)`} stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none">
            <circle cx="18.5" cy="17.5" r="3.5" />
            <circle cx="5.5"  cy="17.5" r="3.5" />
            <circle cx="15"   cy="5"    r="1"   />
            <path d="M12 17.5V14l-3-3 4-3 2 3h2" />
          </g>

          {/*  Info overlay  */}
          <text x="14" y="24"
            fontSize="10" fill="#71717a"
            fontFamily="monospace" letterSpacing="0.08em"
          >LEFT BLIND SPOT</text>

          {dist > 0 && dist !== -1 ? (
            <text x="14" y="44" fontSize="15" fill={objColor} fontFamily="monospace" fontWeight="700">
              {dist < 304.8 ? `${(dist / 25.4).toFixed(1)} in` : `${(dist / 304.8).toFixed(1)} ft`}
            </text>
          ) : (
            <text x="14" y="44" fontSize="12" fill="#a1a1aa" fontFamily="monospace">no reading</text>
          )}

          {/* Blind spot warning text */}
          {blindSpotAlert && (
            <text
              x="200" y="346"
              textAnchor="middle" fontSize="13"
              fill="#f97316" fontFamily="monospace" fontWeight="bold"
            >
              ⚠  OBJECT IN BLIND SPOT
            </text>
          )}
        </svg>
      </div>

      {/*  Mic level bar  */}
      <div className="px-5 py-2.5 border-t border-zinc-200 space-y-1">
        <div className="flex justify-between text-[10px] text-zinc-600 uppercase tracking-wider">
          <span>Noise Level</span>
          <span className="font-mono">{mic} / 4095</span>
        </div>
        <div className="h-1.5 rounded-full bg-zinc-200 overflow-hidden">
          <div
            className={cn(
              'h-full rounded-full transition-all duration-150',
              mic > 800 ? 'bg-yellow-500/60' : 'bg-indigo-500/60',
            )}
            style={{ width: `${(mic / 4095) * 100}%` }}
          />
        </div>
      </div>
    </div>
  );
}
