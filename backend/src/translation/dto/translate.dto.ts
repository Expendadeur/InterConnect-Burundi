import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';

export class TranslateDto {
  @ApiProperty({ example: 'Ndashaka kumenya ibijanye n igihugu cawe.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  text: string;

  @ApiPropertyOptional({ example: 'fr' })
  @IsOptional()
  @IsString()
  targetLanguage?: string;

  @ApiPropertyOptional({ example: 'fr' })
  @IsOptional()
  @IsString()
  target_language?: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  sourceLanguage?: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  source_language?: string;
}
