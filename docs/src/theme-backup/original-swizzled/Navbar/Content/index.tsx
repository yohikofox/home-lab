import React, {type ReactNode} from 'react';
import {
  useThemeConfig,
  ErrorCauseBoundary,
} from '@docusaurus/theme-common';
import {
  splitNavbarItems,
  useNavbarMobileSidebar,
} from '@docusaurus/theme-common/internal';
import NavbarItem, {type Props as NavbarItemConfig} from '@theme/NavbarItem';
import NavbarColorModeToggle from '@theme/Navbar/ColorModeToggle';
import SearchBar from '@theme/SearchBar';
import NavbarMobileSidebarToggle from '@theme/Navbar/MobileSidebar/Toggle';
import NavbarLogo from '@theme/Navbar/Logo';
import NavbarSearch from '@theme/Navbar/Search';
import { 
  NavigationMenu, 
  NavigationMenuContent,
  NavigationMenuItem, 
  NavigationMenuLink, 
  NavigationMenuList,
  NavigationMenuTrigger
} from '../../../components/ui/navigation-menu';
import { Button } from '../../../components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '../../../components/ui/sheet';
import { Menu } from 'lucide-react';
import { cn } from '../../../lib/utils';

function useNavbarItems() {
  return useThemeConfig().navbar.items as NavbarItemConfig[];
}

function ShadcnNavbarItems({items}: {items: NavbarItemConfig[]}): ReactNode {
  return (
    <NavigationMenu>
      <NavigationMenuList className="hidden md:flex space-x-6">
        {items.map((item, i) => (
          <NavigationMenuItem key={i}>
            <ErrorCauseBoundary
              onError={(error) =>
                new Error(
                  `A theme navbar item failed to render.
Please double-check the following navbar item (themeConfig.navbar.items) of your Docusaurus config:
${JSON.stringify(item, null, 2)}`,
                  {cause: error},
                )
              }>
              {/* Wrap original NavbarItem in ShadcnUI styling */}
              <div className="relative">
                <NavbarItem {...item} />
              </div>
            </ErrorCauseBoundary>
          </NavigationMenuItem>
        ))}
      </NavigationMenuList>
    </NavigationMenu>
  );
}

function MobileNavigation({items}: {items: NavbarItemConfig[]}): ReactNode {
  const mobileSidebar = useNavbarMobileSidebar();
  
  return (
    <Sheet>
      <SheetTrigger asChild className="md:hidden">
        <Button variant="ghost" size="icon">
          <Menu className="h-5 w-5" />
          <span className="sr-only">Toggle menu</span>
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-[300px] sm:w-[400px]">
        <nav className="flex flex-col space-y-4">
          <div className="border-b pb-4">
            <NavbarLogo />
          </div>
          <div className="flex flex-col space-y-3">
            {items.map((item, i) => (
              <ErrorCauseBoundary key={i}
                onError={(error) =>
                  new Error(
                    `A theme navbar item failed to render.
Please double-check the following navbar item (themeConfig.navbar.items) of your Docusaurus config:
${JSON.stringify(item, null, 2)}`,
                    {cause: error},
                  )
                }>
                <div className="px-3 py-2 text-sm font-medium">
                  <NavbarItem {...item} />
                </div>
              </ErrorCauseBoundary>
            ))}
          </div>
        </nav>
      </SheetContent>
    </Sheet>
  );
}

export default function NavbarContent(): ReactNode {
  const mobileSidebar = useNavbarMobileSidebar();
  const items = useNavbarItems();
  const [leftItems, rightItems] = splitNavbarItems(items);
  const searchBarItem = items.find((item) => item.type === 'search');

  return (
    <>
      {/* Left section */}
      <div className="flex items-center space-x-4 flex-1">
        {/* Mobile menu */}
        {!mobileSidebar.disabled && (
          <div className="md:hidden">
            <MobileNavigation items={[...leftItems, ...rightItems]} />
          </div>
        )}
        
        {/* Logo */}
        <div className="flex items-center">
          <NavbarLogo />
        </div>

        {/* Desktop navigation */}
        <div className="hidden md:flex">
          <ShadcnNavbarItems items={leftItems} />
        </div>
      </div>

      {/* Right section */}
      <div className="flex items-center space-x-4">
        {/* Right navigation items */}
        <div className="hidden md:flex">
          <ShadcnNavbarItems items={rightItems} />
        </div>

        {/* Search */}
        {!searchBarItem && (
          <NavbarSearch>
            <SearchBar />
          </NavbarSearch>
        )}

        {/* Color mode toggle */}
        <NavbarColorModeToggle />
      </div>
    </>
  );
}