import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { User } from '../../domain/user.entity';
import { UserRepository } from '../../domain/user.repository';
import { UserMapper } from './user.mapper';

@Injectable()
export class UserPrismaRepository implements UserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    const model = await this.prisma.user.findUnique({ where: { id } });
    return model ? UserMapper.toDomain(model) : null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const model = await this.prisma.user.findUnique({ where: { email } });
    return model ? UserMapper.toDomain(model) : null;
  }

  async create(input: { email: string; name: string }): Promise<User> {
    const model = await this.prisma.user.create({ data: input });
    return UserMapper.toDomain(model);
  }
}
