import type {Plugin} from '@docusaurus/types';

const tailwindPlugin: Plugin = function (context, options) {
  return {
    name: 'tailwind-plugin',
    configurePostCss(postcssOptions) {
      postcssOptions.plugins.push(require('@tailwindcss/postcss'));
      postcssOptions.plugins.push(require('autoprefixer'));
      return postcssOptions;
    },
  };
};

export default tailwindPlugin;