import type {Plugin} from '@docusaurus/types';
import path from 'path';
import fs from 'fs';

const aliasPlugin: Plugin = function (context, options) {
  return {
    name: 'alias-plugin',
    configureWebpack(config, isServer, utils) {
      // Lire le tsconfig.json
      const tsconfigPath = path.resolve(context.siteDir, 'tsconfig.json');
      let webpackAliases = {};
      
      try {
        if (fs.existsSync(tsconfigPath)) {
          // Lire et nettoyer le JSON (enlever les commentaires)
          const tsconfigContent = fs.readFileSync(tsconfigPath, 'utf8')
            .replace(/\/\*[\s\S]*?\*\//g, '') // Enlever /* */
            .replace(/\/\/.*$/gm, ''); // Enlever // comments
          const tsconfig = JSON.parse(tsconfigContent);
          const paths = tsconfig.compilerOptions?.paths;
          
          if (paths) {
            // Convertir les alias TypeScript en alias Webpack
            Object.keys(paths).forEach(aliasKey => {
              const aliasPath = paths[aliasKey][0]; // Prendre le premier path
              
              // Nettoyer l'alias key (enlever /*)
              const cleanAlias = aliasKey.replace('/*', '');
              
              // Nettoyer l'alias path (enlever /*) et résoudre le chemin absolu
              const cleanPath = aliasPath.replace('/*', '');
              const resolvedPath = path.resolve(context.siteDir, cleanPath);
              
              webpackAliases[cleanAlias] = resolvedPath;
            });
          }
        }
      } catch (error) {
        console.warn('Could not read tsconfig.json for alias configuration:', error);
      }
      
      // Si pas d'alias trouvés dans tsconfig, utiliser des alias par défaut
      if (Object.keys(webpackAliases).length === 0) {
        webpackAliases = {
          '@': path.resolve(context.siteDir, 'src'),
          '@/components': path.resolve(context.siteDir, 'src/components'),
          '@/lib': path.resolve(context.siteDir, 'src/lib'),
          '@/hooks': path.resolve(context.siteDir, 'src/hooks'),
        };
      }
      
      console.log('🔧 Webpack Aliases configured:', webpackAliases);
      
      return {
        resolve: {
          alias: webpackAliases,
        },
      };
    },
  };
};

export default aliasPlugin;