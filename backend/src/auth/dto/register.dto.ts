import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
  Matches,
  IsOptional,
  Length,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'janviernzambimana91@gmail.com' })
  @IsEmail({}, { message: 'Please provide a valid email address' })
  email: string;

  @ApiProperty({ example: 'Expendadeur', minLength: 3, maxLength: 50 })
  @IsString()
  @Length(3, 50)
  @Matches(/^[a-zA-Z0-9_.-]+$/, {
    message: 'username can only contain letters, numbers, underscores, dots and hyphens',
  })
  username: string;

  @ApiProperty({
    example: 'Pass1234!',
    description: 'Minimum 6 caractères',
  })
  @IsString()
  @MinLength(6)
  @MaxLength(128)
  password: string;

  @ApiProperty({ example: 'Janvier', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  firstName?: string;

  @ApiProperty({ example: 'Expendadeur', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  lastName?: string;

  @ApiProperty({ example: 'rn', required: false })
  @IsOptional()
  @IsString()
  preferredLanguage?: string;

  @ApiProperty({ example: 'https://...', required: false })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiProperty({ example: 'Bujumbura, Burundi', required: false })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiProperty({ example: '+25761234567', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  phone?: string;

  @ApiProperty({ example: 'CNI-BI-123456789', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  nationalId?: string;

  @ApiProperty({ example: 'Burundi', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  country?: string;
}
