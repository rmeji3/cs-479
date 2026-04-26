'use client';
import { useState, useEffect } from 'react';

export interface Settings {
  age: number;
  emergencyName: string;
  emergencyPhone: string;
}

const DEFAULTS: Settings = { age: 30, emergencyName: '', emergencyPhone: '' };
const STORAGE_KEY = 'cyclewatch_settings';

export function useSettings() {
  const [settings, setSettings] = useState<Settings>(DEFAULTS);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setSettings({ ...DEFAULTS, ...JSON.parse(raw) });
    } catch { /* ignore */ }
    setLoaded(true);
  }, []);

  function save(next: Partial<Settings>) {
    const updated = { ...settings, ...next };
    setSettings(updated);
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(updated)); } catch { /* ignore */ }
  }

  return { settings, save, loaded, maxHR: 220 - settings.age };
}
