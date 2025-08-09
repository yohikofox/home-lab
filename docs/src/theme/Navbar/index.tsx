import React from "react";

// 🎯 Navbar minimale - Structure de base fonctionnelle
export default function Navbar() {
  return (
    <header className="navbar sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur h-16">
      <div className="mx-auto flex h-full items-center justify-between px-4 max-w-7xl">
        {/* Left: Logo */}
        <div className="flex items-center space-x-4">
          <a href="/" className="flex items-center space-x-2 font-bold text-lg">
            <div className="h-8 w-8 bg-primary rounded-md" />
            <span className="hidden sm:inline">My Site</span>
          </a>
        </div>

        {/* Right: Placeholder */}
        <div className="flex items-center space-x-2">
          <div className="h-9 w-9 bg-muted rounded-md" />
        </div>
      </div>
    </header>
  );
}
