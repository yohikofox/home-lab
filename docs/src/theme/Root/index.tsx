import React, { useEffect } from 'react';

export default function Root({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Observer pour synchroniser les classes Tailwind avec data-theme de Docusaurus
    const syncTheme = () => {
      const root = document.documentElement;
      const currentTheme = root.getAttribute('data-theme');
      
      // Toujours nettoyer d'abord
      root.classList.remove('dark', 'light');
      
      // Appliquer la classe correspondante
      if (currentTheme === 'dark') {
        root.classList.add('dark');
      } else {
        root.classList.add('light');
      }
      
      console.log('Theme synced:', currentTheme, 'Classes:', Array.from(root.classList));
    };

    // Synchronisation initiale avec délai pour s'assurer que Docusaurus a fini l'initialisation
    const initialSync = () => {
      syncTheme();
      // Backup sync après un court délai
      setTimeout(syncTheme, 100);
      setTimeout(syncTheme, 500);
    };
    
    initialSync();

    // Observer les changements de data-theme
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'data-theme') {
          syncTheme();
        }
      });
    });

    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    });

    // Observer aussi les changements de classe pour débugger
    const classObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
          const root = document.documentElement;
          const hasThemeClass = root.classList.contains('dark') || root.classList.contains('light');
          if (!hasThemeClass) {
            console.warn('Theme classes removed, resyncing...');
            syncTheme();
          }
        }
      });
    });

    classObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class']
    });

    return () => {
      observer.disconnect();
      classObserver.disconnect();
    };
  }, []);

  return <>{children}</>;
}