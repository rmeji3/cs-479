'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeft, Heart, Phone, Save, Bike, CheckCircle2 } from 'lucide-react';
import { useSettings } from '@/hooks/useSettings';

const HR_ZONES = [
  { name: 'Z1 · Warm-up',   range: [0.50, 0.60] as [number, number], color: 'bg-blue-500',   text: 'text-blue-400' },
  { name: 'Z2 · Fat Burn',  range: [0.60, 0.70] as [number, number], color: 'bg-green-500',  text: 'text-green-400' },
  { name: 'Z3 · Cardio',    range: [0.70, 0.80] as [number, number], color: 'bg-yellow-500', text: 'text-yellow-400' },
  { name: 'Z4 · Threshold', range: [0.80, 0.90] as [number, number], color: 'bg-orange-500', text: 'text-orange-400' },
  { name: 'Z5 · Max',       range: [0.90, 1.00] as [number, number], color: 'bg-red-500',    text: 'text-red-400' },
];

export default function SettingsPage() {
  const { settings, save, loaded } = useSettings();

  const [age, setAge]     = useState(String(settings.age));
  const [name, setName]   = useState(settings.emergencyName);
  const [phone, setPhone] = useState(settings.emergencyPhone);
  const [saved, setSaved] = useState(false);

  // Sync once localStorage is hydrated
  useEffect(() => {
    if (loaded) {
      setAge(String(settings.age));
      setName(settings.emergencyName);
      setPhone(settings.emergencyPhone);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [loaded]);

  const ageNum = Math.max(10, Math.min(100, parseInt(age, 10) || 30));
  const maxHR  = 220 - ageNum;

  function handlePhoneChange(raw: string) {
    // Strip everything except digits and leading +
    let digits = raw.replace(/[^\d]/g, '');
    // Always store with +1 prefix
    if (digits.startsWith('1') && digits.length > 1) digits = digits.slice(1);
    setPhone(digits ? `+1${digits}` : '');
  }

  function handleSave() {
    save({ age: ageNum, emergencyName: name, emergencyPhone: phone });
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">

      {/* Header */}
      <header className="flex items-center gap-3 px-4 h-11 border-b border-zinc-800 shrink-0">
        <div className="flex items-center gap-2">
          <Bike size={16} className="text-blue-400" />
          <span className="text-sm font-bold tracking-tight">CycleWatch</span>
        </div>
        <span className="text-zinc-700 text-xs">·</span>
        <Link
          href="/"
          className="flex items-center gap-1.5 text-xs text-zinc-500 hover:text-zinc-200 transition-colors"
        >
          <ArrowLeft size={12} />
          Dashboard
        </Link>
        <span className="ml-auto text-xs text-zinc-600 font-semibold uppercase tracking-widest">Settings</span>
      </header>

      <div className="max-w-md mx-auto px-4 py-8 space-y-8">

        {/* ── Heart Rate Zones ──────────────────────────── */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Heart size={14} className="text-red-400" />
            <h2 className="text-xs font-bold uppercase tracking-widest text-zinc-400">
              Heart Rate Zones
            </h2>
          </div>

          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-5">

            {/* Age input */}
            <div className="flex items-center gap-4">
              <label htmlFor="age-input" className="text-sm text-zinc-400 shrink-0">Your Age</label>
              <input
                id="age-input"
                type="number"
                min={10}
                max={100}
                value={age}
                onChange={e => setAge(e.target.value)}
                onBlur={() => setAge(String(ageNum))}
                className="w-24 bg-zinc-800 border border-zinc-700 hover:border-zinc-600
                           focus:border-blue-500 focus:outline-none
                           rounded-lg px-3 py-2.5 text-3xl font-black tabular-nums text-white
                           text-center transition-colors"
              />
            </div>

            {/* Max HR result */}
            <div className="pt-1 border-t border-zinc-800 space-y-3">
              <div className="flex items-baseline gap-2">
                <p className="text-xs text-zinc-500">Max HR <span className="text-zinc-700">(220 − age)</span></p>
                <span className="ml-auto text-2xl font-black text-red-400 tabular-nums">{maxHR}</span>
                <span className="text-zinc-500 text-xs">bpm</span>
              </div>

              {/* Zone breakdown */}
              <div className="space-y-1.5">
                {HR_ZONES.map(z => {
                  const lo = Math.round(z.range[0] * maxHR);
                  const hi = Math.round(z.range[1] * maxHR);
                  // Bar width relative to 100% maxHR
                  const barLeft  = z.range[0] * 100;
                  const barWidth = (z.range[1] - z.range[0]) * 100;
                  return (
                    <div key={z.name} className="flex items-center gap-2 text-xs">
                      <div className={`w-2 h-2 rounded-full shrink-0 ${z.color}`} />
                      <span className={`w-28 shrink-0 ${z.text}`}>{z.name}</span>
                      <div className="flex-1 relative h-1 bg-zinc-800 rounded-full overflow-hidden">
                        <div
                          className={`absolute h-full rounded-full ${z.color}`}
                          style={{ left: `${barLeft}%`, width: `${barWidth}%` }}
                        />
                      </div>
                      <span className="text-zinc-500 tabular-nums font-mono w-20 text-right shrink-0">
                        {lo}–{hi} bpm
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </section>

        {/* ── Emergency Contact ─────────────────────────── */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Phone size={14} className="text-emerald-400" />
            <h2 className="text-xs font-bold uppercase tracking-widest text-zinc-400">
              Emergency Contact
            </h2>
          </div>

          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
            <p className="text-xs text-zinc-500 leading-relaxed">
              If a crash is detected and you don't dismiss the alert within 10 seconds, this
              contact will receive an automated phone call via Twilio.
            </p>

            <div className="space-y-1.5">
              <label className="text-xs text-zinc-400" htmlFor="contact-name">Name</label>
              <input
                id="contact-name"
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="Jane Smith"
                autoComplete="off"
                className="w-full bg-zinc-800 border border-zinc-700 hover:border-zinc-600
                           focus:border-blue-500 focus:outline-none
                           rounded-lg px-3 py-2.5 text-sm text-white placeholder:text-zinc-600
                           transition-colors"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs text-zinc-400" htmlFor="contact-phone">Phone Number</label>
              <div className="flex items-center bg-zinc-800 border border-zinc-700 hover:border-zinc-600
                              focus-within:border-blue-500 rounded-lg overflow-hidden transition-colors">
                <span className="px-3 text-sm text-zinc-500 font-mono shrink-0 border-r border-zinc-700 py-2.5">+1</span>
                <input
                  id="contact-phone"
                  type="tel"
                  value={phone.replace(/^\+1/, '')}
                  onChange={e => handlePhoneChange(e.target.value)}
                  placeholder="555 000 1234"
                  autoComplete="off"
                  className="flex-1 bg-transparent px-3 py-2.5 text-sm text-white placeholder:text-zinc-600
                             focus:outline-none font-mono tracking-wide"
                />
              </div>
              <p className="text-[10px] text-zinc-600">US/Canada numbers only (auto +1)</p>
            </div>
          </div>
        </section>

        {/* ── Save ─────────────────────────────────────── */}
        <button
          onClick={handleSave}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl font-bold text-sm
                     bg-blue-600 hover:bg-blue-500 active:scale-[0.98] text-white transition-all"
        >
          {saved ? (
            <>
              <CheckCircle2 size={15} />
              Saved!
            </>
          ) : (
            <>
              <Save size={15} />
              Save Settings
            </>
          )}
        </button>



      </div>
    </div>
  );
}
