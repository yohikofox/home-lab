import React, { useState } from "react";
import { NavbarItem, useThemeConfig } from "@docusaurus/theme-common";
import { useLocation } from "@docusaurus/router";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  Menu,
  X,
  ChevronRight,
  ChevronDown,
  FileText,
  Folder,
} from "lucide-react";
import ColorModeToggle from "./ColorModeToggle";

// 📱 Mobile First: Hamburger + Title + Dark/Light Toggle
export default function Navbar() {
  const {
    navbar: { title, items = [], logo },
  } = useThemeConfig();

  const location = useLocation();

  // Détecter si on est sur une page docs
  const isDocsPage = location.pathname.startsWith("/docs");

  // Pour l'instant, on va hardcode quelques éléments de sidebar pour tester
  const mockDocsSidebar = isDocsPage
    ? {
        items: [
          {
            type: "link",
            label: "Home Lab Documentation",
            href: "/docs/intro",
          },
          {
            type: "link",
            label: "Architecture",
            href: "/docs/ARCHITECTURE",
          },
          {
            type: "link",
            label: "Installation",
            href: "/docs/INSTALLATION",
          },
          {
            type: "category",
            label: "Network",
            items: [
              {
                type: "link",
                label: "Network Topology",
                href: "/docs/architecture/network-topology",
              },
            ],
          },
        ],
      }
    : null;

  const leftItems = items.filter((item) => item.position !== "right");
  const rightItems = items.filter((item) => item.position === "right");
  const logoUrl = useBaseUrl(logo?.src || "");

  const [isOpen, setIsOpen] = useState(true);

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

              <ScrollArea className="h-[calc(100vh-5rem)]">
                <nav className="mt-8 px-4">
                  {/* Navigation items */}
                  <div className="space-y-2 mb-6">
                    {items.map((item: NavbarItem, index: number) => {
                      const href =
                        item.href ||
                        item.to ||
                        (item.type === "docSidebar" ? "/docs/intro" : "#");

                      return (
                        <Link
                          key={index}
                          href={href}
                          className="block px-4 py-2 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
                          onClick={() => setIsOpen(false)}
                        >
                          {item.label}
                        </Link>
                      );
                    })}
                  </div>

                  {/* Documentation sidebar si on est sur une page docs */}
                  {isDocsPage && mockDocsSidebar && (
                    <>
                      <div className="border-t border-border pt-6 mb-4">
                        <h3 className="font-semibold text-foreground mb-4">
                          Documentation
                        </h3>
                      </div>

                      <div className="space-y-1">
                        {mockDocsSidebar.items.map((item, index) => (
                          <SidebarItem
                            key={index}
                            item={item}
                            activePath={location.pathname}
                            onItemClick={() => setIsOpen(false)}
                          />
                        ))}
                      </div>
                    </>
                  )}
                </nav>
              </ScrollArea>
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
              <img
                src={logoUrl}
                alt={logo.alt || title}
                className="h-8 w-auto"
              />
            )}
            <span className="font-bold text-foreground text-xl">{title}</span>
          </Link>

          {leftItems.map((item, index) => {
            // Handle different navbar item types
            const href =
              item.href ||
              item.to ||
              (item.type === "docSidebar" ? "/docs/intro" : "#");

            return (
              <Link
                key={index}
                href={href}
                className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
              >
                {item.label}
              </Link>
            );
          })}
        </div>

        {/* 💻 Desktop: Right Group (Right Nav + Toggle) */}
        <div className="hidden md:flex items-center space-x-6">
          {rightItems.map((item, index) => {
            const href =
              item.href ||
              item.to ||
              (item.type === "docSidebar" ? "/docs/intro" : "#");

            return (
              <Link
                key={index}
                href={href}
                className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
              >
                {item.label}
              </Link>
            );
          })}

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

// Composant pour chaque item de la sidebar mobile
function SidebarItem({
  item,
  activePath,
  onItemClick,
}: {
  item: any; // PropSidebarItem
  activePath: string;
  onItemClick: () => void;
}) {
  const [isOpen, setIsOpen] = useState(false); // ← Fermé par défaut

  if (item.type === "link") {
    const isActive = activePath === item.href;

    return (
      <Link
        href={item.href}
        className={`
          flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors
          ${
            isActive
              ? "bg-primary text-primary-foreground font-medium"
              : "text-muted-foreground hover:text-foreground hover:bg-accent"
          }
        `}
        onClick={onItemClick}
      >
        <FileText className="h-4 w-4" />
        {item.label}
      </Link>
    );
  }

  if (item.type === "category") {
    return (
      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <Button
            variant="ghost"
            className="w-full justify-start px-3 py-2 h-auto text-sm font-medium text-foreground hover:bg-accent relative"
          >
            {/* Chevron en position absolue */}
            <span className="absolute left-[-5px] top-1/2 -translate-y-1/2">
              {isOpen ? (
                <ChevronDown className="h-4 w-4" />
              ) : (
                <ChevronRight className="h-4 w-4" />
              )}
            </span>
            {/* Contenu aligné avec les documents - même padding que les links */}
            <div className="flex items-center gap-2">
              <Folder className="h-4 w-4" />
              {item.label}
            </div>
          </Button>
        </CollapsibleTrigger>

        <CollapsibleContent className="ml-4 space-y-1">
          {item.items.map((subItem, subIndex) => (
            <SidebarItem
              key={subIndex}
              item={subItem}
              activePath={activePath}
              onItemClick={onItemClick}
            />
          ))}
        </CollapsibleContent>
      </Collapsible>
    );
  }

  return null;
}
