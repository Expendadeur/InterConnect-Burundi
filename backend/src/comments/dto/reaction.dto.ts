import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';
import { ReactionType } from '../entities/reaction.entity';

export class ToggleReactionDto {
  @ApiProperty({ enum: ReactionType, example: ReactionType.LIKE })
  @IsEnum(ReactionType)
  reactionType: ReactionType;

  @ApiPropertyOptional({ example: 'post-uuid' })
  @IsOptional()
  @IsUUID()
  postId?: string;

  @ApiPropertyOptional({ example: 'comment-uuid' })
  @IsOptional()
  @IsUUID()
  commentId?: string;
}

