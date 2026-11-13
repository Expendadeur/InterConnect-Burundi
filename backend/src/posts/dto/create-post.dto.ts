import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsString,
  IsOptional,
  IsUrl,
  IsArray,
  MaxLength,
  IsNotEmpty,
  Length,
} from 'class-validator';
import { PostType } from '../entities/post.entity';

export class CreatePostDto {
  @ApiProperty({ enum: PostType, example: PostType.TEXT })
  @IsEnum(PostType)
  type: PostType;

  @ApiProperty({ example: 'Bonjour Burundi! 🇧🇮' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  content: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/media/post.jpg' })
  @IsOptional()
  @IsUrl()
  mediaUrl?: string;

  @ApiPropertyOptional({ example: 'https://example.com' })
  @IsOptional()
  @IsUrl()
  linkUrl?: string;

  @ApiPropertyOptional({ example: ['technology', 'burundi'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ example: 'fr' })
  @IsOptional()
  @IsString()
  @Length(2, 10)
  originalLanguage?: string;
}
