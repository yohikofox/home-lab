import React from 'react';
import {useThemeConfig, useColorMode} from '@docusaurus/theme-common';
import {useHideableNavbar} from '@docusaurus/theme-common/internal';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import { cn } from '../../lib/utils';
import { Button } from '../../components/ui/button';
import { Sheet, SheetContent, SheetTrigger, SheetHeader, SheetTitle } from '../../components/ui/sheet';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../components/ui/dropdown-menu';
import { Menu, Sun, Moon, Monitor, Github, Rss, Home, BookOpen, ExternalLink } from 'lucide-react';

function Logo() {
  const {navbar: {title, logo}} = useThemeConfig();
  const logoSrc = useBaseUrl(logo?.src || '');
  
  return (
    <Link to="/" className="flex items-center space-x-2 font-bold text-lg hover:opacity-80">
      {logo && <img src={logoSrc} alt={logo.alt || title} className="h-8 w-8" />}
      <span className="hidden sm:inline">{title}</span>
    </Link>
  );
}

function ColorModeToggle() {
  const {colorMode, setColorMode} = useColorMode();
  
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-9 w-9">
          <Sun className="h-4 w-4 rotate-0 scale-100 transition-transform dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-transform dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        <DropdownMenuItem onClick={() => setColorMode('light')}>
          <Sun className="mr-2 h-4 w-4" />
          Light
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setColorMode('dark')}>
          <Moon className="mr-2 h-4 w-4" />
          Dark
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setColorMode('auto')}>
          <Monitor className="mr-2 h-4 w-4" />
          System
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function NavLink({to, href, children, icon: Icon}: {
  to?: string;
  href?: string;
  children: React.ReactNode;
  icon?: React.ComponentType<any>;
}) {
  const isExternal = href && !href.startsWith('/');
  const linkClass = "flex items-center text-sm font-medium transition-colors hover:text-primary px-3 py-2";
  
  if (href) {
    return (
      <Link href={href} {...(isExternal && { target: '_blank', rel: 'noopener noreferrer' })} className={linkClass}>
        {Icon && <Icon className="mr-2 h-4 w-4" />}
        {children}
        {isExternal && <ExternalLink className="ml-1 h-3 w-3" />}
      </Link>
    );
  }
  
  return (
    <Link to={to} className={linkClass}>
      {Icon && <Icon className="mr-2 h-4 w-4" />}
      {children}
    </Link>
  );
}

function MobileMenu() {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="md:hidden h-9 w-9">
          <Menu className="h-5 w-5" />
          <span className="sr-only">Toggle menu</span>
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-80 p-0">
        <SheetHeader className="border-b px-6 py-4">
          <SheetTitle className="text-left">
            <Logo />
          </SheetTitle>
        </SheetHeader>
        <div className="flex flex-col space-y-1 p-6">
          <Link to="/" className="flex items-center text-sm font-medium py-3 px-3 rounded-md hover:bg-accent transition-colors">
            <Home className="mr-3 h-4 w-4" />
            Home
          </Link>
          
          <Link to="/docs/intro" className="flex items-center text-sm font-medium py-3 px-3 rounded-md hover:bg-accent transition-colors">
            <BookOpen className="mr-3 h-4 w-4" />
            Tutorial
          </Link>
          
          <Link to="/blog" className="flex items-center text-sm font-medium py-3 px-3 rounded-md hover:bg-accent transition-colors">
            <Rss className="mr-3 h-4 w-4" />
            Blog
          </Link>
          
          <div className="border-t pt-4 mt-4">
            <Link href="https://github.com/facebook/docusaurus" target="_blank" rel="noopener noreferrer" className="flex items-center text-sm font-medium py-3 px-3 rounded-md hover:bg-accent transition-colors">
              <Github className="mr-3 h-4 w-4" />
              GitHub
              <ExternalLink className="ml-auto h-3 w-3" />
            </Link>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}

function DesktopNavigation() {
  return (
    <nav className="hidden md:flex items-center space-x-1">
      <NavLink to="/docs/intro" icon={BookOpen}>Tutorial</NavLink>
      <NavLink to="/blog" icon={Rss}>Blog</NavLink>
      <NavLink href="https://github.com/facebook/docusaurus" icon={Github}>GitHub</NavLink>
    </nav>
  );
}

export default function Navbar() {
  const {navbar: {hideOnScroll}} = useThemeConfig();
  const {navbarRef, isNavbarVisible} = useHideableNavbar(hideOnScroll);
  
  return (
    <header 
      ref={navbarRef}
      className={cn(
        'sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur h-16',
        hideOnScroll && 'transition-transform duration-200',
        hideOnScroll && !isNavbarVisible && '-translate-y-full'
      )}
    >
      <div className="mx-auto flex h-full items-center justify-between px-4 max-w-7xl">
        <div className="flex items-center space-x-4">
          <MobileMenu />
          <Logo />
          <DesktopNavigation />
        </div>
        
        <ColorModeToggle />
      </div>
    </header>
  );
}