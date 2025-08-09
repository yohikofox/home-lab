import React, {type ReactNode} from 'react';
import {ThemeClassNames} from '@docusaurus/theme-common';
import type {Props} from '@theme/Footer/Layout';
import { cn } from '../../../lib/utils';
import { Separator } from '../../../components/ui/separator';

export default function FooterLayout({
  style,
  links,
  logo,
  copyright,
}: Props): ReactNode {
  return (
    <footer
      className={cn(
        // Base ShadcnUI footer styles
        'border-t border-border bg-background',
        // Docusaurus compatibility
        ThemeClassNames.layout.footer.container,
        'footer',
        {
          'footer--dark': style === 'dark',
        },
      )}>
      <div className="container mx-auto max-w-screen-2xl px-4 py-8">
        {/* Footer links */}
        {links && (
          <div className="mb-8">
            {links}
          </div>
        )}
        
        {/* Footer bottom section */}
        {(logo || copyright) && (
          <>
            <Separator className="mb-6" />
            <div className="flex flex-col items-center space-y-4 text-center sm:flex-row sm:justify-between sm:space-y-0">
              {/* Logo */}
              {logo && (
                <div className="flex items-center">
                  {logo}
                </div>
              )}
              
              {/* Copyright */}
              {copyright && (
                <div className="text-sm text-muted-foreground">
                  {copyright}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </footer>
  );
}