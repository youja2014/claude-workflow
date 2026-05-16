import { LoginForm } from '@/features/auth-login';

export function HomePage() {
  return (
    <main className="min-h-screen flex items-center justify-center p-8">
      <div className="max-w-md w-full">
        <h1 className="text-3xl font-bold mb-6">__project_name__</h1>
        <p className="text-sm text-gray-500 mb-8">__description__</p>
        <LoginForm />
      </div>
    </main>
  );
}
