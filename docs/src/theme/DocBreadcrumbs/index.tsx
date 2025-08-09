import React, {type ReactNode} from 'react';
import clsx from 'clsx';
import {ThemeClassNames} from '@docusaurus/theme-common';
import {useSidebarBreadcrumbs} from '@docusaurus/plugin-content-docs/client';
import {useHomePageRoute} from '@docusaurus/theme-common/internal';
import Link from '@docusaurus/Link';
import {translate} from '@docusaurus/Translate';
import HomeBreadcrumbItem from '@theme/DocBreadcrumbs/Items/Home';
import DocBreadcrumbsStructuredData from '@theme/DocBreadcrumbs/StructuredData';

import styles from './styles.module.css';

// TODO move to design system folder
function BreadcrumbsItemLink({
  children,
  href,
  isLast,
}: {
  children: ReactNode;
  href: string | undefined;
  isLast: boolean;
}): ReactNode {
  const className = isLast 
    ? 'text-foreground font-medium text-sm truncate max-w-[200px] md:max-w-none' 
    : 'text-muted-foreground hover:text-foreground transition-colors text-sm truncate max-w-[150px] md:max-w-none';
  
  if (isLast) {
    return <span className={className} title={children as string}>{children}</span>;
  }
  return href ? (
    <Link className={className} href={href} title={children as string}>
      <span>{children}</span>
    </Link>
  ) : (
    <span className={className} title={children as string}>{children}</span>
  );
}

// TODO move to design system folder
function BreadcrumbsItem({
  children,
  active,
}: {
  children: ReactNode;
  active?: boolean;
}): ReactNode {
  return (
    <div className="flex items-center">
      {children}
    </div>
  );
}

export default function DocBreadcrumbs(): ReactNode {
  const breadcrumbs = useSidebarBreadcrumbs();
  const homePageRoute = useHomePageRoute();

  if (!breadcrumbs) {
    return null;
  }

  return (
    <>
      <DocBreadcrumbsStructuredData breadcrumbs={breadcrumbs} />
      <nav
        className="flex items-center space-x-2 text-sm text-muted-foreground mb-6 px-0 md:px-0"
        aria-label={translate({
          id: 'theme.docs.breadcrumbs.navAriaLabel',
          message: 'Breadcrumbs',
          description: 'The ARIA label for the breadcrumbs',
        })}>
        <div className="flex items-center space-x-2">
          {homePageRoute && <HomeBreadcrumbItem />}
          {breadcrumbs.map((item, idx) => {
            const isLast = idx === breadcrumbs.length - 1;
            const href =
              item.type === 'category' && item.linkUnlisted
                ? undefined
                : item.href;
            return (
              <React.Fragment key={idx}>
                {(homePageRoute || idx > 0) && (
                  <span className="text-muted-foreground/60">/</span>
                )}
                <BreadcrumbsItem active={isLast}>
                  <BreadcrumbsItemLink href={href} isLast={isLast}>
                    {item.label}
                  </BreadcrumbsItemLink>
                </BreadcrumbsItem>
              </React.Fragment>
            );
          })}
        </div>
      </nav>
    </>
  );
}
