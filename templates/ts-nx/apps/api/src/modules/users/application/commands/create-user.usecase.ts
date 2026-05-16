import { Inject, Injectable } from '@nestjs/common';
import {
  USER_REPOSITORY,
  UserRepository,
} from '../../domain/user.repository';
import { User } from '../../domain/user.entity';
import { EmailAlreadyTakenException } from '../../domain/exceptions';

export interface CreateUserInput {
  email: string;
  name: string;
}

@Injectable()
export class CreateUserUseCase {
  constructor(@Inject(USER_REPOSITORY) private readonly users: UserRepository) {}

  async execute(input: CreateUserInput): Promise<User> {
    const existing = await this.users.findByEmail(input.email);
    if (existing) {
      throw new EmailAlreadyTakenException(input.email);
    }
    return this.users.create({ email: input.email, name: input.name });
  }
}
