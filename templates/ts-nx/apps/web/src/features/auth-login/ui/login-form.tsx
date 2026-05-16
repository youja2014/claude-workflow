import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/shared/ui/button';
import { LoginSchema, type LoginValues } from '../model/schema';
import { useLogin } from '../api/use-login';

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginValues>({ resolver: zodResolver(LoginSchema) });

  const login = useLogin();

  const onSubmit = handleSubmit((values) => {
    login.mutate(values);
  });

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <label className="block text-sm mb-1" htmlFor="email">
          Email
        </label>
        <input
          id="email"
          type="email"
          {...register('email')}
          className="w-full h-10 px-3 rounded border"
        />
        {errors.email && <p className="text-sm text-red-600 mt-1">{errors.email.message}</p>}
      </div>
      <div>
        <label className="block text-sm mb-1" htmlFor="password">
          Password
        </label>
        <input
          id="password"
          type="password"
          {...register('password')}
          className="w-full h-10 px-3 rounded border"
        />
        {errors.password && (
          <p className="text-sm text-red-600 mt-1">{errors.password.message}</p>
        )}
      </div>
      <Button type="submit" disabled={isSubmitting || login.isPending} className="w-full">
        {login.isPending ? 'Signing in...' : 'Sign in'}
      </Button>
      {login.isError && <p className="text-sm text-red-600">Login failed</p>}
    </form>
  );
}
