import React from 'react';
import { useEffect } from 'react';

// Script inline pour éviter le flash pendant l'hydratation
const ThemeInitScript = `
(function() {
  try {
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const theme = savedTheme || (prefersDark ? 'dark' : 'light');
    
    const root = document.documentElement;
    
    // Clear existing classes
    root.classList.remove('dark', 'light');
    
    // Add the correct theme class immediately
    if (theme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.add('light');
    }
  } catch (e) {
    console.warn('Theme initialization failed:', e);
  }
})();
`;

export default function Root({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Ensure theme consistency after hydration
    const ensureThemeConsistency = () => {
      const root = document.documentElement;
      const docusaurusTheme = document.documentElement.getAttribute('data-theme');
      
      if (docusaurusTheme === 'dark' && !root.classList.contains('dark')) {
        root.classList.remove('light');
        root.classList.add('dark');
      } else if (docusaurusTheme === 'light' && !root.classList.contains('light')) {
        root.classList.remove('dark');
        root.classList.add('light');
      }
    };

    // Run immediately
    ensureThemeConsistency();

    // Also run when data-theme changes (fallback)
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'data-theme') {
          ensureThemeConsistency();
        }
      });
    });

    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    });

    return () => observer.disconnect();
  }, []);

  return (
    <>
      <script
        dangerouslySetInnerHTML={{
          __html: ThemeInitScript,
        }}
      />
      {children}
    </>
  );
}