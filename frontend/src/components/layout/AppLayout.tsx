import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';

/**
 * Layout principal del sistema (cuando el usuario está autenticado).
 * Renderiza Sidebar + área de contenido. Cada página dentro del Outlet
 * decide si mostrar Header con title específico.
 */
export function AppLayout() {
  return (
    <div className="flex min-h-screen bg-bg-base">
      <Sidebar />
      <main className="flex-1 min-w-0 flex flex-col">
        <Outlet />
      </main>
    </div>
  );
}
