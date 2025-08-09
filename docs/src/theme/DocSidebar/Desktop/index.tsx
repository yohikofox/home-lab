import React from 'react';
import type {Props} from '@theme/DocSidebar/Desktop';

// 🎯 DocSidebar Desktop minimal
export default function DocSidebarDesktop({path, sidebar, onCollapse, isHidden}: Props) {
  if (isHidden) {
    return null;
  }

  return (
    <div 
      className="flex h-full w-64 flex-col border-r bg-background theme-doc-sidebar-container"
      id="__docusaurus_sidebar"
      style={{ minHeight: '100vh' }}
    >
      <div className="p-4">
        <div className="text-sm text-muted-foreground">
          Desktop Sidebar ({sidebar?.length || 0} items)
        </div>
        {sidebar?.map((item, i) => (
          <div key={i} className="py-1 text-sm">
            {item.label || `Item ${i + 1}`}
          </div>
        ))}
      </div>
    </div>
  );
}