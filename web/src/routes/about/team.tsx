import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/about/team')({
  component: TeamComponent,
  loader: () => ({
    crumb: 'Team'
  })
});

function TeamComponent() {
  return <h1 className='raleway3'>Team</h1>;
}
