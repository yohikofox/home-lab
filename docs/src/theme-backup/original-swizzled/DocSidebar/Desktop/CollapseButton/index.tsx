import React, {type ReactNode} from 'react';
import {translate} from '@docusaurus/Translate';
import IconArrow from '@theme/Icon/Arrow';
import type {Props} from '@theme/DocSidebar/Desktop/CollapseButton';
import { Button } from '../../../../components/ui/button';
import { ChevronLeft } from 'lucide-react';

export default function CollapseButton({onClick}: Props): ReactNode {
  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      title={translate({
        id: 'theme.docs.sidebar.collapseButtonTitle',
        message: 'Collapse sidebar',
        description: 'The title attribute for collapse button of doc sidebar',
      })}
      aria-label={translate({
        id: 'theme.docs.sidebar.collapseButtonAriaLabel',
        message: 'Collapse sidebar',
        description: 'The title attribute for collapse button of doc sidebar',
      })}
      onClick={onClick}
      className="w-full justify-start gap-2"
    >
      <ChevronLeft className="h-4 w-4" />
      Collapse sidebar
    </Button>
  );
}