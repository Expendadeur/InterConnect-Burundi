import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { TranslateDto } from './dto/translate.dto';

export interface TranslationResult {
  originalText: string;
  translatedText: string;
  sourceLanguage: string;
  targetLanguage: string;
  provider: string;
  cached?: boolean;
}

@Injectable()
export class TranslationService {
  private readonly logger = new Logger(TranslationService.name);
  private readonly aiServiceUrl: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly httpService: HttpService,
  ) {
    this.aiServiceUrl = this.configService.get<string>('aiService.url', 'http://ai-translation:8000');
  }

  async translate(dto: TranslateDto): Promise<TranslationResult> {
    const text = dto.text;
    const targetLang = dto.targetLanguage;
    const sourceLang = dto.sourceLanguage || 'auto';

    try {
      if (this.aiServiceUrl && this.aiServiceUrl.startsWith('http')) {
        const response = await firstValueFrom(
          this.httpService.post(`${this.aiServiceUrl}/translate`, {
            text,
            source_language: sourceLang,
            target_language: targetLang,
          }, { timeout: 4000 }),
        );

        if (response?.data?.translated_text) {
          return {
            originalText: text,
            translatedText: response.data.translated_text,
            sourceLanguage: response.data.source_language || sourceLang,
            targetLanguage: response.data.target_language || targetLang,
            provider: response.data.provider || 'fastapi-ai',
          };
        }
      }
    } catch (_) {}

    return {
      originalText: text,
      translatedText: text,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      provider: 'fallback-echo',
    };
  }
}

