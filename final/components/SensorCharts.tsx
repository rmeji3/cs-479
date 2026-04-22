'use client';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ReferenceLine,
} from 'recharts';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { BLIND_SPOT_THRESHOLD_MM, FALL_THRESHOLD, SPO2_LOW } from '@/lib/constants';
import type { ChartPoint } from '@/hooks/useSensorData';

interface Props {
  history: ChartPoint[];
}

const tooltipStyle = {
  backgroundColor: '#18181b',
  border: '1px solid #3f3f46',
  borderRadius: 8,
  fontSize: 11,
  color: '#a1a1aa',
};

function MiniChart({
  title,
  dataKey,
  color,
  data,
  domain,
  unit,
  refLine,
}: {
  title: string;
  dataKey: keyof ChartPoint;
  color: string;
  data: ChartPoint[];
  domain?: [number | 'auto', number | 'auto'];
  unit?: string;
  refLine?: number;
}) {
  return (
    <div className="space-y-1">
      <p className="text-xs text-zinc-500 uppercase tracking-wider pl-1">{title}</p>
      <ResponsiveContainer width="100%" height={80}>
        <LineChart data={data} margin={{ top: 4, right: 4, left: -24, bottom: 0 }}>
          <XAxis dataKey="ts" hide />
          <YAxis domain={domain ?? ['auto', 'auto']} tick={{ fontSize: 9, fill: '#71717a' }} width={36} unit={unit} />
          <Tooltip
            contentStyle={tooltipStyle}
            labelFormatter={() => ''}
          formatter={(v) => [`${v ?? ''}${unit ?? ''}`, title]}
          />
          {refLine !== undefined && (
            <ReferenceLine y={refLine} stroke="#ef4444" strokeDasharray="3 3" strokeWidth={1} />
          )}
          <Line
            type="monotone"
            dataKey={dataKey}
            stroke={color}
            dot={false}
            strokeWidth={1.5}
            isAnimationActive={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export function SensorCharts({ history }: Props) {
  return (
    <Card className="bg-zinc-900 border-zinc-800">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold uppercase tracking-widest text-zinc-400">
          Live Charts
        </CardTitle>
      </CardHeader>
      <CardContent className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <MiniChart
          title="Distance (mm)"
          dataKey="dist"
          color="#f97316"
          data={history}
          domain={[0, 2000]}
          refLine={BLIND_SPOT_THRESHOLD_MM}
        />
        <MiniChart
          title="Accel Magnitude (m/s²)"
          dataKey="accel_mag"
          color="#ef4444"
          data={history}
          domain={[0, 30]}
          refLine={FALL_THRESHOLD}
        />
        <MiniChart
          title="SpO₂ (%)"
          dataKey="spo2"
          color="#22d3ee"
          data={history}
          domain={[85, 100]}
          unit="%"
          refLine={SPO2_LOW}
        />
        <MiniChart
          title="Heart Rate (BPM)"
          dataKey="bpm"
          color="#a78bfa"
          data={history}
          domain={[40, 180]}
        />
        <MiniChart
          title="Mic Peak (ADC)"
          dataKey="mic"
          color="#4ade80"
          data={history}
          domain={[0, 4095]}
        />
      </CardContent>
    </Card>
  );
}
