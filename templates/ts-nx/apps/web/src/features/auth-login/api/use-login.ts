import { useMutation } from '@tanstack/react-query';
import { apiClient } from '@/shared/api/client';
import type { LoginValues } from '../model/schema';

interface LoginResponse {
  token: string;
}

export function useLogin() {
  return useMutation({
    mutationFn: async (input: LoginValues): Promise<LoginResponse> => {
      const { data } = await apiClient.post<LoginResponse>('/auth/login', input);
      return data;
    },
  });
}
