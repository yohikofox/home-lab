import React, {type ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import isInternalUrl from '@docusaurus/isInternalUrl';
import IconExternalLink from '@theme/Icon/ExternalLink';
import type {Props} from '@theme/Footer/LinkItem';
import { cn } from '../../../lib/utils';
import { ExternalLink } from 'lucide-react';

export default function FooterLinkItem({item}: Props): ReactNode {
  const {to, href, label, prependBaseUrlToHref, className, ...props} = item;
  const toUrl = useBaseUrl(to);
  const normalizedHref = useBaseUrl(href, {forcePrependBaseUrl: true});

  return (
    <Link
      className={cn(
        // ShadcnUI link styles
        'inline-flex items-center gap-1 text-muted-foreground transition-colors hover:text-foreground',
        // Docusaurus compatibility
        'footer__link-item',
        className
      )}
      {...(href
        ? {
            href: prependBaseUrlToHref ? normalizedHref : href,
          }
        : {
            to: toUrl,
          })}
      {...props}>
      {label}
      {href && !isInternalUrl(href) && (
        <ExternalLink className="ml-1 h-3 w-3" />
      )}
    </Link>
  );
}