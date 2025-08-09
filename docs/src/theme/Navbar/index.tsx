import React, { useState } from "react";
import { NavbarItem, useThemeConfig } from "@docusaurus/theme-common";
import Link from "@docusaurus/Link";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { Menu, X } from "lucide-react";
import ColorModeToggle from "./ColorModeToggle";

// 📱 Mobile First: Hamburger + Title + Dark/Light Toggle
export default function Navbar() {
  const {
    navbar: { title, items = [], logo },
  } = useThemeConfig();

  const leftItems = items.filter((item) => item.position !== "right");
  const rightItems = items.filter((item) => item.position === "right");

  const [isOpen, setIsOpen] = useState(false);

  return (
    <header className="navbar bg-background border-b border-border sticky top-0 z-50">
      <div className="w-full px-4 h-16 flex items-center justify-between">
        {/* 📱 Mobile: Hamburger */}
        <div className="flex items-center md:hidden">
          <Sheet open={isOpen} onOpenChange={setIsOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon">
                <Menu className="h-5 w-5" />
                <span className="sr-only">Toggle menu</span>
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-80">
              <SheetHeader>
                <SheetTitle>{title}</SheetTitle>
              </SheetHeader>
              <nav className="mt-8">
                <div className="space-y-2">
                  {items.map((item: NavbarItem, index: number) => (
                    <Link
                      key={index}
                      href={(item.href as string) || (item.to as string)}
                      className="block px-4 py-2 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
                      onClick={() => setIsOpen(false)}
                    >
                      {item.label}
                    </Link>
                  ))}
                </div>
              </nav>
            </SheetContent>
          </Sheet>
        </div>

        {/* 📱 Mobile: Title Centered */}
        <div className="flex-1 md:hidden">
          <Link
            href="/"
            className="font-bold text-foreground text-xl block text-center"
          >
            {title}
          </Link>
        </div>

        {/* 💻 Desktop: Left Group (Logo + Title + Left Nav) */}
        <div className="hidden md:flex items-center space-x-6">
          <Link href="/" className="flex items-center space-x-3">
            {logo?.src && (
              <img src={logo.src} alt={logo.alt || title} className="h-8 w-8" />
            )}
            <span className="font-bold text-foreground text-xl">{title}</span>
          </Link>

          {leftItems.map((item, index) => (
            <Link
              key={index}
              href={(item.href as string) || (item.to as string)}
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              {item.label}
            </Link>
          ))}
        </div>

        {/* 💻 Desktop: Right Group (Right Nav + Toggle) */}
        <div className="hidden md:flex items-center space-x-6">
          {rightItems.map((item, index) => (
            <Link
              key={index}
              href={(item.href as string) || (item.to as string)}
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              {item.label}
            </Link>
          ))}

          <ColorModeToggle />
        </div>

        {/* 📱 Mobile: Toggle only */}
        <div className="flex items-center md:hidden">
          <ColorModeToggle />
        </div>
      </div>
    </header>
  );
}
