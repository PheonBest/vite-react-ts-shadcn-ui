import { createFileRoute, Link } from '@tanstack/react-router';

export const Route = createFileRoute('/about/')({
  component: About
});

function About() {
  return (
    <div>
      <h1 className='raleway3'>About</h1>
      <ul className='list-inside list-disc'>
        <li>
          <Link to='/about/projects/'>Our projects</Link>
        </li>
        <li>
          <Link to='/about/team/'>Our team</Link>
        </li>
        <li>
          <Link to='/about/vision/'>Our vision</Link>
        </li>
      </ul>
    </div>
  );
}
