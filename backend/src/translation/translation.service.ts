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
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.aiServiceUrl}/translate`, {
          text: dto.text,
          source_language: dto.sourceLanguage,
          target_language: dto.targetLanguage,
        }),
      );

      return {
        originalText: response.data.original_text,
        translatedText: response.data.translated_text,
        sourceLanguage: response.data.source_language,
        targetLanguage: response.data.target_language,
        provider: response.data.provider,
        cached: response.data.cached,
      };
    } catch (error) {
      this.logger.error(`Erreur d'appel au microservice IA: ${error.message}`);
      // Fallback gracieux en cas d'indisponibilité du service IA
      return {
        originalText: dto.text,
        translatedText: dto.text,
        sourceLanguage: dto.sourceLanguage || 'unknown',
        targetLanguage: dto.targetLanguage,
        provider: 'fallback-echo',
      };
    }
  }
}

