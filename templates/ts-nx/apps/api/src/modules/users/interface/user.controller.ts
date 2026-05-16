import {
  Body,
  ConflictException,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { CreateUserUseCase } from '../application/commands/create-user.usecase';
import { EmailAlreadyTakenException } from '../domain/exceptions';
import { CreateUserDto } from './dto/create-user.dto';
import { UserResponseDto } from './dto/user.response.dto';

@Controller('users')
export class UserController {
  constructor(private readonly createUser: CreateUserUseCase) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateUserDto): Promise<UserResponseDto> {
    try {
      const user = await this.createUser.execute({ email: dto.email, name: dto.name });
      return UserResponseDto.from(user);
    } catch (err) {
      if (err instanceof EmailAlreadyTakenException) {
        throw new ConflictException(err.message);
      }
      throw err;
    }
  }
}
