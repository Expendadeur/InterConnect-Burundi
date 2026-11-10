import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEnum,
  IsArray,
  MaxLength,
} from 'class-validator';
import { PostType, PostVisibility } from '../entities/post.entity';

export class CreatePostDto {
  @ApiPropertyOptional({ example: 'Ndashaka kumenya ibijanye n igihugu cawe.' })
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  content?: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  originalLanguage?: string;

  @ApiPropertyOptional({ example: ['https://storage.interconnect.bi/img.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaUrls?: string[];

  @ApiPropertyOptional({ enum: PostType, default: PostType.TEXT })
  @IsOptional()
  @IsEnum(PostType)
  postType?: PostType;

  @ApiPropertyOptional({ enum: PostVisibility, default: PostVisibility.PUBLIC })
  @IsOptional()
  @IsEnum(PostVisibility)
  visibility?: PostVisibility;
}

