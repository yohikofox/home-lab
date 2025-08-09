import React from 'react';
import { Button } from '../../components/ui/button';
import { Sheet, SheetContent, SheetTrigger, SheetHeader, SheetTitle } from '../../components/ui/sheet';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../components/ui/dropdown-menu';
import { Menu, Sun, Moon, Monitor } from 'lucide-react';

// ========================================
// 🎯 COMPORTEMENTS SOUHAITÉS
// ========================================
// ✅ Mobile: Hamburger menu avec Sheet
// ✅ Desktop: Navigation horizontale 
// ✅ Logo cliquable vers home
// ✅ Toggle dark/light mode
// ✅ Hide on scroll (optionnel)
// ✅ Responsive simple (mobile/desktop)

// ========================================
// 🧱 BRIQUES À IMPLÉMENTER PROGRESSIVEMENT  
// ========================================
// 🔄 Lecture config navbar items
// 🔄 Support type: 'docSidebar' 
// 🔄 Support type: 'dropdown'
// 🔄 Position left/right
// 🔄 Liens externes avec icône
// 🔄 Logo depuis config

// ========================================
// 🎨 STRUCTURE SIMPLE
// ========================================

function Logo() {
  return (
    <a href="/" className="flex items-center space-x-2 font-bold text-lg">
      <div className="h-8 w-8 bg-primary rounded-md" />
      <span className="hidden sm:inline">My Site</span>
    </a>
  );
}

function ColorModeToggle() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem><Sun className="mr-2 h-4 w-4" />Light</DropdownMenuItem>
        <DropdownMenuItem><Moon className="mr-2 h-4 w-4" />Dark</DropdownMenuItem>
        <DropdownMenuItem><Monitor className="mr-2 h-4 w-4" />System</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function MobileMenu() {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="md:hidden">
          <Menu className="h-5 w-5" />
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-80 p-0">
        <SheetHeader className="border-b px-6 py-4">
          <SheetTitle className="text-left">
            <Logo />
          </SheetTitle>
        </SheetHeader>
        <nav className="p-6 space-y-2">
          <a href="/docs" className="block py-2 px-3 rounded hover:bg-accent">Tutorial</a>
          <a href="/blog" className="block py-2 px-3 rounded hover:bg-accent">Blog</a>
          <a href="https://github.com" className="block py-2 px-3 rounded hover:bg-accent">GitHub</a>
        </nav>
      </SheetContent>
    </Sheet>
  );
}

function DesktopNav() {
  return (
    <nav className="hidden md:flex items-center space-x-1">
      <a href="/docs" className="px-3 py-2 text-sm hover:text-primary">Tutorial</a>
      <a href="/blog" className="px-3 py-2 text-sm hover:text-primary">Blog</a>
      <a href="https://github.com" className="px-3 py-2 text-sm hover:text-primary">GitHub</a>
    </nav>
  );
}

export default function SimpleNavbar() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur h-16">
      <div className="mx-auto flex h-full items-center justify-between px-4 max-w-7xl">
        
        {/* Left */}
        <div className="flex items-center space-x-4">
          <MobileMenu />
          <Logo />
          <DesktopNav />
        </div>
        
        {/* Right */}
        <ColorModeToggle />
        
      </div>
    </header>
  );
}