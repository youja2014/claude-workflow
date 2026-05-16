import { CreateUserUseCase } from './create-user.usecase';
import { EmailAlreadyTakenException } from '../../domain/exceptions';
import { User } from '../../domain/user.entity';
import { UserRepository } from '../../domain/user.repository';

class FakeUserRepository implements UserRepository {
  private byEmail = new Map<string, User>();
  private nextId = 1;

  async findById(id: string): Promise<User | null> {
    for (const u of this.byEmail.values()) if (u.id === id) return u;
    return null;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.byEmail.get(email) ?? null;
  }

  async create(input: { email: string; name: string }): Promise<User> {
    const user = new User(String(this.nextId++), input.email, input.name, new Date());
    this.byEmail.set(input.email, user);
    return user;
  }
}

describe('CreateUserUseCase', () => {
  it('creates a new user', async () => {
    const repo = new FakeUserRepository();
    const useCase = new CreateUserUseCase(repo);

    const user = await useCase.execute({ email: 'alice@example.com', name: 'Alice' });

    expect(user.email).toBe('alice@example.com');
    expect(user.name).toBe('Alice');
  });

  it('rejects duplicate email', async () => {
    const repo = new FakeUserRepository();
    const useCase = new CreateUserUseCase(repo);
    await useCase.execute({ email: 'dup@x.com', name: 'A' });

    await expect(
      useCase.execute({ email: 'dup@x.com', name: 'B' }),
    ).rejects.toBeInstanceOf(EmailAlreadyTakenException);
  });
});
