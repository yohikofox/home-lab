import React from 'react';
import {useThemeConfig} from '@docusaurus/theme-common';
import Logo from '@theme/Logo';
import CollapseButton from '@theme/DocSidebar/Desktop/CollapseButton';
import Content from '@theme/DocSidebar/Desktop/Content';
import type {Props} from '@theme/DocSidebar/Desktop';
import { cn } from '../../../lib/utils';
import { ScrollArea } from '../../../components/ui/scroll-area';
import { Separator } from '../../../components/ui/separator';

function DocSidebarDesktop({path, sidebar, onCollapse, isHidden}: Props) {
  const {
    navbar: {hideOnScroll},
    docs: {
      sidebar: {hideable},
    },
  } = useThemeConfig();

  return (
    <div
      className={cn(
        // Base ShadcnUI sidebar styles
        'flex h-full w-full flex-col border-r border-border bg-background',
        // Docusaurus compatibility
        'theme-doc-sidebar-container',
        // Hide/show states
        isHidden && 'hidden',
        // Navbar scroll behavior
        hideOnScroll && 'pt-navbar-height',
      )}>
      
      {/* Logo when navbar is hideable */}
      {hideOnScroll && (
        <div className="flex items-center border-b border-border p-4">
          <Logo tabIndex={-1} />
        </div>
      )}

      {/* Sidebar content with scroll */}
      <ScrollArea className="flex-1">
        <div className="p-4">
          <Content path={path} sidebar={sidebar} />
        </div>
      </ScrollArea>

      {/* Collapse button */}
      {hideable && (
        <>
          <Separator />
          <div className="p-2">
            <CollapseButton onClick={onCollapse} />
          </div>
        </>
      )}
    </div>
  );
}

export default React.memo(DocSidebarDesktop);