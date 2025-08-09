import React from "react";
import { useThemeConfig } from "@docusaurus/theme-common";
import Link from "@docusaurus/Link";
// import MobileMenu from "./MobileMenu";
import ColorModeToggle from "./ColorModeToggle";
import { Button } from '@/components/ui/button';

// 📱 Mobile First: Hamburger + Title + Dark/Light Toggle
export default function Navbar() {
  const {
    navbar: { title },
  } = useThemeConfig();

  return (
    <header className="navbar bg-background border-b border-border sticky top-0 z-50">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        <div className="font-bold text-foreground">{title}</div>
        <div className="flex items-center gap-4">
          <Button variant="outline" size="sm">
            ShadcnUI Test
          </Button>
          <div className="text-muted-foreground">Tailwind Test</div>
        </div>
      </div>
    </header>
  );
}
