import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, MaxLength } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ example: 'Ego cane, urakoze cane!' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  content: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  originalLanguage?: string;

  @ApiPropertyOptional({ example: 'parent-comment-uuid' })
  @IsOptional()
  @IsUUID()
  parentCommentId?: string;
}

