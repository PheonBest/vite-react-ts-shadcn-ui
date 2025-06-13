import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/about/vision')({
  component: VisionComponent,
  loader: () => ({
    crumb: 'Vision'
  })
});

function VisionComponent() {
  return <h1 className='raleway3'>Vision</h1>;
}
