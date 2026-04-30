'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeft, Heart, Phone, Save, Bike, CheckCircle2 } from 'lucide-react';
import { useSettings } from '@/hooks/useSettings';

export default function SettingsPage() {
  const { settings, save, loaded } = useSettings();

  const [age, setAge]     = useState(String(settings.age));
  const [name, setName]   = useState(settings.emergencyName);
  const [phone, setPhone] = useState(settings.emergencyPhone);
  const [saved, setSaved] = useState(false);

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
    <div className="min-h-screen bg-white text-zinc-950">

      {/* Header */}
      <header className="flex items-center gap-3 px-4 h-11 border-b border-zinc-200 shrink-0">
        <div className="flex items-center gap-2">
          <Bike size={16} className="text-blue-400" />
          <span className="text-sm font-bold tracking-tight">CycleWatch</span>
        </div>
        <span className="text-zinc-400 text-xs">·</span>
        <Link
          href="/"
          className="flex items-center gap-1.5 text-xs text-zinc-600 hover:text-zinc-900 transition-colors"
        >
          <ArrowLeft size={12} />
          Dashboard
        </Link>
        <span className="ml-auto text-xs text-zinc-600 font-semibold uppercase tracking-widest">Settings</span>
      </header>

      <div className="max-w-md mx-auto px-4 py-8 space-y-8">

        {/*  Heart Rate Zones  */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Heart size={14} className="text-red-400" />
            <h2 className="text-xs font-bold uppercase tracking-widest text-zinc-400">
              Heart Rate Zones
            </h2>
          </div>

          <div className="bg-white border border-zinc-200 rounded-2xl p-5 space-y-5">

            {/* Age input */}
            <div className="flex items-center gap-4">
              <label htmlFor="age-input" className="text-sm text-zinc-600 shrink-0">Your Age</label>
              <input
                id="age-input"
                type="number"
                min={10}
                max={100}
                value={age}
                onChange={e => setAge(e.target.value)}
                onBlur={() => setAge(String(ageNum))}
                className="w-24 bg-zinc-100 border border-zinc-300 hover:border-zinc-400
                           focus:border-blue-500 focus:outline-none
                           rounded-lg px-3 py-2.5 text-3xl font-black tabular-nums text-zinc-950
                           text-center transition-colors"
              />
            </div>

            {/* Max HR result */}
              <div className="pt-1 border-t border-zinc-200 space-y-3">
              <div className="flex items-baseline gap-2">
                <p className="text-xs text-zinc-600">Max HR <span className="text-zinc-500">(220 − age)</span></p>
                <span className="ml-auto text-2xl font-black text-red-600 tabular-nums">{maxHR}</span>
                <span className="text-zinc-500 text-xs">bpm</span>
              </div>
            </div>
          </div>
        </section>

        {/*  Emergency Contact  */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Phone size={14} className="text-emerald-600" />
            <h2 className="text-xs font-bold uppercase tracking-widest text-zinc-600">
              Emergency Contact
            </h2>
          </div>

          <div className="bg-white border border-zinc-200 rounded-2xl p-5 space-y-4">
            <p className="text-xs text-zinc-600 leading-relaxed">
              If a crash is detected and you don't dismiss the alert within 10 seconds, this
              contact will receive an automated phone call via Twilio.
            </p>

            <div className="space-y-1.5">
              <label className="text-xs text-zinc-600" htmlFor="contact-name">Name</label>
              <input
                id="contact-name"
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="First Last"
                autoComplete="off"
                className="w-full bg-zinc-100 border border-zinc-300 hover:border-zinc-400
                           focus:border-blue-500 focus:outline-none
                           rounded-lg px-3 py-2.5 text-sm text-zinc-950 placeholder:text-zinc-500
                           transition-colors"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs text-zinc-600" htmlFor="contact-phone">Phone Number</label>
              <div className="flex items-center bg-zinc-100 border border-zinc-300 hover:border-zinc-400
                              focus-within:border-blue-500 rounded-lg overflow-hidden transition-colors">
                <span className="px-3 text-sm text-zinc-600 font-mono shrink-0 border-r border-zinc-300 py-2.5">+1</span>
                <input
                  id="contact-phone"
                  type="tel"
                  value={phone.replace(/^\+1/, '')}
                  onChange={e => handlePhoneChange(e.target.value)}
                  placeholder="555 000 1234"
                  autoComplete="off"
                  className="flex-1 bg-transparent px-3 py-2.5 text-sm text-zinc-950 placeholder:text-zinc-500
                             focus:outline-none font-mono tracking-wide"
                />
              </div>
            </div>
          </div>
        </section>

        {/*  Save  */}
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
