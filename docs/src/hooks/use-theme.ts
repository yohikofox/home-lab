import { useColorMode } from '@docusaurus/theme-common';
import { useEffect } from 'react';

// 🎯 Hook personnalisé pour gérer ShadcnUI dark mode avec Docusaurus
export function useTheme() {
  const { colorMode, setColorMode } = useColorMode();

  // Sync with ShadcnUI dark mode classes
  useEffect(() => {
    const root = window.document.documentElement;
    
    // Force sync - remove both classes first to avoid conflicts
    root.classList.remove('dark', 'light');
    
    if (colorMode === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.add('light');
    }
  }, [colorMode]);

  const toggleTheme = () => {
    setColorMode(colorMode === 'light' ? 'dark' : 'light');
  };

  return {
    theme: colorMode,
    isDark: colorMode === 'dark',
    isLight: colorMode === 'light',
    toggleTheme,
    setTheme: setColorMode,
  };
}