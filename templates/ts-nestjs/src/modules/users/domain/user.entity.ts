export class User {
  constructor(
    public readonly id: string,
    public readonly email: string,
    public readonly name: string,
    public readonly createdAt: Date,
  ) {}

  static create(input: { email: string; name: string }): Omit<User, 'id' | 'createdAt'> & {
    email: string;
    name: string;
  } {
    return { email: input.email, name: input.name };
  }
}
