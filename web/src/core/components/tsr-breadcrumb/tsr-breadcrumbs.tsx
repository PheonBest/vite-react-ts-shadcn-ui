import { Link } from '@tanstack/react-router';

import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator
} from '@/core/components/ui/breadcrumb';

import { useTSRBreadCrumbs } from './use-tsr-breadcrumbs';

export function TSRBreadCrumbs() {
  const { breadcrumbItems } = useTSRBreadCrumbs();

  console.log(breadcrumbItems);

  if (breadcrumbItems.length < 2) return;

  return (
    <Breadcrumb>
      <BreadcrumbList>
        {breadcrumbItems.map((item, i) => (
          <div key={item.href} className='flex items-center gap-2'>
            <BreadcrumbItem>
              {i < breadcrumbItems.length - 1 ? (
                <Link to={item.href} className='hover:text-accent-text'>
                  {item.label}
                </Link>
              ) : (
                <BreadcrumbPage>{item.label}</BreadcrumbPage>
              )}
            </BreadcrumbItem>
            {i < breadcrumbItems.length - 1 && <BreadcrumbSeparator />}
          </div>
        ))}
      </BreadcrumbList>
    </Breadcrumb>
  );
}
