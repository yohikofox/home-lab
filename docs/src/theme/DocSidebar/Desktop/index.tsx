import React from "react";
import type { Props } from "@theme/DocSidebar/Desktop";

// 🎯 DocSidebar Desktop minimal
export default function DocSidebarDesktop({
  path,
  sidebar,
  onCollapse,
  isHidden,
}: Props) {
  if (isHidden) {
    return null;
  }

  return <></>;
}
