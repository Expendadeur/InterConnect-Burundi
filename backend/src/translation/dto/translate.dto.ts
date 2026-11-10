import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';

export class TranslateDto {
  @ApiProperty({ example: 'Ndashaka kumenya ibijanye n igihugu cawe.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  text: string;

  @ApiProperty({ example: 'fr' })
  @IsString()
  @IsNotEmpty()
  targetLanguage: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  sourceLanguage?: string;
}

