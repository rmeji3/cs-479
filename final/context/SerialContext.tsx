'use client';
import { createContext, useContext } from 'react';
import { useSerial, UseSerialReturn } from '@/hooks/useSerial';

const SerialContext = createContext<UseSerialReturn | null>(null);

export function SerialProvider({ children }: { children: React.ReactNode }) {
  const serial = useSerial();
  return <SerialContext.Provider value={serial}>{children}</SerialContext.Provider>;
}

export function useSerialContext(): UseSerialReturn {
  const ctx = useContext(SerialContext);
  if (!ctx) throw new Error('useSerialContext must be used inside SerialProvider');
  return ctx;
}
