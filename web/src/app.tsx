import { StrictMode, useEffect } from 'react';

import { createRouter, RouterProvider } from '@tanstack/react-router';

import { DefaultCatchBoundary } from '@/core/components/default-catch-bounrdary';
import { NotFound } from '@/core/components/not-found';
// Import the generated route tree
import { useThemeStore } from '@/stores/theme';

import { routeTree } from './routeTree.gen';

// Create a new router instance
const router = createRouter({
  routeTree,
  trailingSlash: 'always',
  defaultPreload: 'intent',
  basepath: import.meta.env.VITE_BASE_PATH,
  defaultErrorComponent: DefaultCatchBoundary,
  defaultNotFoundComponent: () => <NotFound />
});
// Register the router instance for type safety
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

function App() {
  const setTheme = useThemeStore((state) => state.setTheme);

  useEffect(() => {
    // Initialize page's theme based on user's preferences
    const theme = useThemeStore.getState().theme;
    setTheme(theme);
  }, [setTheme]);

  return (
    <StrictMode>
      <RouterProvider router={router} />
    </StrictMode>
  );
}

export default App;
