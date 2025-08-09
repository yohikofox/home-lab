/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { type ReactNode } from "react";
import clsx from "clsx";
import { useDocsSidebar } from "@docusaurus/plugin-content-docs/client";
import type { Props } from "@theme/DocRoot/Layout/Main";

export default function DocRootLayoutMain({
  hiddenSidebarContainer,
  children,
}: Props): ReactNode {
  const sidebar = useDocsSidebar();

  return (
    <main className="flex-1 flex flex-col w-full bg-background">
      <div
        className={clsx(
          "container padding-top--md padding-bottom--lg flex-1",
          hiddenSidebarContainer && "max-w-full"
        )}
      >
        {children}
      </div>
    </main>
  );
}
