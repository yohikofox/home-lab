import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

// Utilitaires HomeLab spécifiques
export function getThemeColor(colorKey: string): string {
  const colors = {
    'homelab-cyan': '#00d4ff',
    'homelab-green': '#39ff14',
    'homelab-blue': '#0066ff',
    'homelab-purple': '#8b5cf6',
    'homelab-orange': '#ff6b35',
  };
  
  return colors[colorKey as keyof typeof colors] || '#00d4ff';
}