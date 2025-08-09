import React, {type ReactNode} from 'react';
import {MDXProvider} from '@mdx-js/react';
import MDXComponents from '@theme/MDXComponents';
import type {Props} from '@theme/MDXContent';

// 🎯 Wrapper MDXContent avec styles Markdown personnalisés
export default function MDXContent({children}: Props): ReactNode {
  return (
    <div className="markdown">
      <MDXProvider components={MDXComponents}>{children}</MDXProvider>
    </div>
  );
}