import { Module } from '@nestjs/common';
import { UserController } from './interface/user.controller';
import { CreateUserUseCase } from './application/commands/create-user.usecase';
import { USER_REPOSITORY } from './domain/user.repository';
import { UserPrismaRepository } from './infrastructure/persistence/user.prisma.repository';

@Module({
  controllers: [UserController],
  providers: [
    CreateUserUseCase,
    { provide: USER_REPOSITORY, useClass: UserPrismaRepository },
  ],
  exports: [CreateUserUseCase],
})
export class UsersModule {}
