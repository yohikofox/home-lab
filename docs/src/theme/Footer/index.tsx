import React from 'react';

// 🎯 Footer minimal - Structure de base  
export default function Footer() {
  return (
    <footer className="border-t bg-background py-6">
      <div className="mx-auto max-w-7xl px-4">
        <div className="text-center text-sm text-muted-foreground">
          © 2025 My Site. Built with Docusaurus & ShadcnUI.
        </div>
      </div>
    </footer>
  );
}