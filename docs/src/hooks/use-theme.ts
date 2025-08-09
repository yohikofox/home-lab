import { useColorMode } from '@docusaurus/theme-common';
import { useEffect } from 'react';

// 🎯 Hook personnalisé pour gérer ShadcnUI dark mode avec Docusaurus
export function useTheme() {
  const { colorMode, setColorMode } = useColorMode();

  // Sync with ShadcnUI dark mode classes
  useEffect(() => {
    const root = window.document.documentElement;
    
    if (colorMode === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
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