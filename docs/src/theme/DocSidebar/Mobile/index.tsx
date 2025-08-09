import React from 'react';
import type {Props} from '@theme/DocSidebar/Mobile';

// 🎯 DocSidebar Mobile minimal  
export default function DocSidebarMobile({path, sidebar}: Props) {
  return (
    <div className="theme-doc-sidebar-mobile">
      <div className="p-4 text-sm text-muted-foreground">
        Mobile Sidebar ({sidebar?.length || 0} items)
      </div>
    </div>
  );
}