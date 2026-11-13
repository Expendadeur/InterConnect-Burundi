import { PartialType, ApiPropertyOptional } from '@nestjs/swagger';
import { CreatePostDto } from './create-post.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { PostStatus } from '../entities/post.entity';

export class UpdatePostDto extends PartialType(CreatePostDto) {
  @ApiPropertyOptional({ enum: PostStatus })
  @IsOptional()
  @IsEnum(PostStatus)
  status?: PostStatus;
}
