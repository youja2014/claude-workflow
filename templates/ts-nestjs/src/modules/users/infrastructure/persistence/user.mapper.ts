import type { User as PrismaUser } from '@prisma/client';
import { User } from '../../domain/user.entity';

export class UserMapper {
  static toDomain(model: PrismaUser): User {
    return new User(model.id, model.email, model.name, model.createdAt);
  }
}
