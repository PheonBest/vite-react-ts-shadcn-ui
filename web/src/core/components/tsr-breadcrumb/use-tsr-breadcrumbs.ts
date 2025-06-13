import { useMatches } from '@tanstack/react-router';

export function useTSRBreadCrumbs() {
  const matches = useMatches();
  console.log('matches', matches);
  const breadcrumbItems = matches
    .filter((match) => match.loaderData?.crumb)
    .map((match) => {
      return {
        href: match.pathname,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        label: match.loaderData!.crumb
      };
    });

  return { breadcrumbItems };
}
