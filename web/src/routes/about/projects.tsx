import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/about/projects')({
  component: ProjectComponent,
  loader: () => ({
    crumb: 'Projects'
  })
});

function ProjectComponent() {
  return <h1 className='raleway3'>Projects</h1>;
}
