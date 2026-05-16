export class UserNotFoundException extends Error {
  constructor(id: string) {
    super(`User not found: ${id}`);
    this.name = 'UserNotFoundException';
  }
}

export class EmailAlreadyTakenException extends Error {
  constructor(email: string) {
    super(`Email already taken: ${email}`);
    this.name = 'EmailAlreadyTakenException';
  }
}
