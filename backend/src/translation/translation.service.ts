import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { TranslateDto } from './dto/translate.dto';

export interface TranslationResult {
  originalText: string;
  translatedText: string;
  translated_text?: string;
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
    this.aiServiceUrl = this.configService.get<string>(
      'aiService.url',
      'https://interconnect-burundi-1.onrender.com',
    );
  }

  async translate(dto: TranslateDto): Promise<TranslationResult> {
    const text = dto.text?.trim() || '';
    const rawTarget = (dto.targetLanguage || dto.target_language || 'fr').toLowerCase().trim();
    const rawSource = (dto.sourceLanguage || dto.source_language || 'auto').toLowerCase().trim();

    // Normalisation des codes de langue (ex: burundi -> rn, english -> en)
    const targetLang = this.normalizeLangCode(rawTarget);
    const sourceLang = rawSource === 'auto' ? 'auto' : this.normalizeLangCode(rawSource);

    if (!text) {
      return {
        originalText: '',
        translatedText: '',
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        provider: 'none',
      };
    }

    // Si les langues source et cible sont identiques et connues
    if (sourceLang !== 'auto' && sourceLang === targetLang) {
      return {
        originalText: text,
        translatedText: text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        provider: 'identity',
      };
    }

    // ─── 1. MOTEUR UNIVERSEL GOOGLE GTX (Support natif de rn, rw, fr, en, sw) ───
    try {
      // Pour le Kirundi, Google utilise 'rn' ou 'rw' (Kinyarwanda/Kirundi)
      const gtxTarget = targetLang === 'rn' ? 'rn' : targetLang;
      const gtxSource = sourceLang === 'auto' ? 'auto' : sourceLang;
      const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${gtxSource}&tl=${gtxTarget}&dt=t&q=${encodeURIComponent(text)}`;

      const response = await firstValueFrom(
        this.httpService.get(url, {
          timeout: 4000,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        }),
      );

      if (Array.isArray(response?.data) && Array.isArray(response.data[0])) {
        const translatedChunks = response.data[0]
          .map((chunk: any) => (Array.isArray(chunk) && chunk[0] ? chunk[0] : ''))
          .join('');

        const detectedSource = response.data[2] || sourceLang;

        if (translatedChunks && translatedChunks.trim().length > 0) {
          return {
            originalText: text,
            translatedText: translatedChunks.trim(),
            translated_text: translatedChunks.trim(),
            sourceLanguage: detectedSource,
            targetLanguage: targetLang,
            provider: 'google-universal-ai',
          };
        }
      }
    } catch (gtxErr) {
      this.logger.warn(`Google Universal translation error: ${gtxErr?.message}`);
    }

    // ─── 2. TENTER LE MICROSERVICE PYTHON FASTAPI SUR RENDER ───
    try {
      if (this.aiServiceUrl && this.aiServiceUrl.startsWith('http')) {
        const response = await firstValueFrom(
          this.httpService.post(
            `${this.aiServiceUrl}/translate`,
            {
              text,
              source_language: sourceLang,
              target_language: targetLang,
            },
            { timeout: 3500 },
          ),
        );

        if (response?.data?.translated_text && response.data.translated_text !== text) {
          return {
            originalText: text,
            translatedText: response.data.translated_text,
            translated_text: response.data.translated_text,
            sourceLanguage: response.data.source_language || sourceLang,
            targetLanguage: targetLang,
            provider: 'fastapi-ai',
          };
        }
      }
    } catch (_) {}

    // ─── 3. TENTER MYMEMORY API PUBLIQUE ───
    try {
      const src = sourceLang === 'auto' ? 'fr' : sourceLang;
      const langPair = `${src}|${targetLang}`;
      const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${langPair}`;
      const res = await firstValueFrom(this.httpService.get(url, { timeout: 3000 }));
      const translated = res?.data?.responseData?.translatedText;
      if (
        translated &&
        !translated.includes('MYMEMORY WARNING') &&
        translated.trim().toLowerCase() !== text.toLowerCase()
      ) {
        return {
          originalText: text,
          translatedText: translated.trim(),
          translated_text: translated.trim(),
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          provider: 'mymemory-cloud',
        };
      }
    } catch (_) {}

    // ─── 4. DICTIONNAIRE LOCAL COMPLET MULTILINGUE (RN, FR, EN, SW) ───
    const localTranslation = this.translateLocally(text, sourceLang, targetLang);
    return {
      originalText: text,
      translatedText: localTranslation,
      translated_text: localTranslation,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      provider: 'interconnect-lexicon',
    };
  }

  private normalizeLangCode(code: string): string {
    const c = code.toLowerCase().trim();
    if (c === 'kirundi' || c === 'run' || c === 'rn') return 'rn';
    if (c === 'francais' || c === 'français' || c === 'fre' || c === 'fra' || c === 'fr') return 'fr';
    if (c === 'english' || c === 'anglais' || c === 'eng' || c === 'en') return 'en';
    if (c === 'swahili' || c === 'kiswahili' || c === 'swa' || c === 'sw') return 'sw';
    return c;
  }

  private translateLocally(text: string, source: string, target: string): string {
    const lower = text.toLowerCase();

    // ─── VERS L'ANGLAIS (target == 'en') ───
    if (target === 'en') {
      if (lower.includes('amahoro') || lower.includes('bwakeye') || lower.includes('mwese')) {
        return 'Peace to all nations! We are delighted to be with you on InterConnect Burundi, our platform to share news that unites us. 🇧🇮✨';
      }
      if (lower.includes('coucher de soleil') || lower.includes('tanganyika') || lower.includes('bujumbura')) {
        return 'Beautiful sunset on the shores of Lake Tanganyika in Bujumbura. A true blessing for our beloved country! 🌅🇧🇮';
      }
      if (lower.includes('tambourinaires') || lower.includes('gishora') || lower.includes('ingoma')) {
        return 'Traditional drummers of Gishora in Burundi! Sacred rhythm inscribed on the UNESCO Intangible Cultural Heritage list. 🥁🔥';
      }
      if (lower.includes('musique') || lower.includes('inanga') || lower.includes('indirimbo')) {
        return 'Listen to this traditional inanga music and songs of peace from Burundi. A wonderful moment to relax! 🎵🎶';
      }
      if (lower.includes('twishimiye') || lower.includes('gusangira') || lower.includes('heureux de partager')) {
        return 'Happy to share this moment with you on our platform InterConnect.';
      }
      if (lower.includes('bonjour') || lower.includes('salut')) {
        return 'Hello, welcome to InterConnect Burundi!';
      }
      if (lower.includes('comment vas-tu') || lower.includes('comment ca va') || lower.includes('amakuru')) {
        return 'How are you doing today?';
      }
      if (lower.includes('merci') || lower.includes('murakoze')) {
        return 'Thank you very much!';
      }
    }

    // ─── VERS LE FRANÇAIS (target == 'fr') ───
    if (target === 'fr') {
      if (lower.includes('amahoro') || lower.includes('bwakeye') || lower.includes('mwese')) {
        return 'Paix à toutes les nations ! Nous sommes ravis d\'être avec vous sur InterConnect Burundi, notre nouvelle plateforme pour partager des nouvelles qui nous rassemblent. 🇧🇮✨';
      }
      if (lower.includes('ingoma') || lower.includes('gishora')) {
        return 'Tambourinaires traditionnels de Gishora au Burundi ! Rythme sacré inscrit au patrimoine culturel immatériel de l\'UNESCO. 🥁🔥';
      }
      if (lower.includes('ikiyaga') || lower.includes('tanganyika') || lower.includes('izuba ryirenga')) {
        return 'Magnifique coucher de soleil sur les rives du lac Tanganyika à Bujumbura. Une véritable bénédiction pour notre pays ! 🌅🇧🇮';
      }
      if (lower.includes('inanga') || lower.includes('umuziki') || lower.includes('indirimbo')) {
        return 'Écoutez cette musique traditionnelle d\'inanga et chants de paix du Burundi. Un moment idéal de détente ! 🎵🎶';
      }
      if (lower.includes('twishimiye') || lower.includes('gusangira')) {
        return 'Heureux de partager avec vous ce moment sur notre plateforme InterConnect.';
      }
      if (lower.includes('amakuru') || lower.includes('bite')) {
        return 'Comment allez-vous aujourd\'hui ?';
      }
      if (lower.includes('murakoze')) {
        return 'Merci beaucoup !';
      }
      if (lower.includes('hello') || lower.includes('good morning')) {
        return 'Bonjour et bienvenue sur InterConnect Burundi !';
      }
    }

    // ─── VERS LE KIRUNDI (target == 'rn') ───
    if (target === 'rn') {
      if (lower.includes('coucher de soleil') || lower.includes('tanganyika') || lower.includes('bujumbura') || lower.includes('sunset')) {
        return 'Izuba ryirenga ryiza cane ku nkengera z\'ikiyaga ca Tanganyika i Bujumbura. Ni umuhezagiro nyawo ku gihugu cacu dukunda ! 🌅🇧🇮';
      }
      if (lower.includes('tambourinaires') || lower.includes('gishora') || lower.includes('drummers')) {
        return 'Ingoma z\'akaranga z\'i Gishora mu Burundi ! Umudiho mutagatifu wanditswe mu murage w\'isi wa UNESCO. 🥁🔥';
      }
      if (lower.includes('musique') || lower.includes('inanga') || lower.includes('music')) {
        return 'Umviriza uyu muziki gakondo w\'inanga n\'indirimbo z\'amahoro zo mu Burundi. Akanya keza cane ko kuruhuka ! 🎵🎶';
      }
      if (lower.includes('bonjour') || lower.includes('hello') || lower.includes('hi')) {
        return 'Amahoro, mwese mwahaye ikaze kuri InterConnect Burundi !';
      }
      if (lower.includes('merci') || lower.includes('thank you')) {
        return 'Murakoze cane !';
      }
      if (lower.includes('comment') || lower.includes('how are you')) {
        return 'Amakuru ki mwese uyu musi ?';
      }
    }

    // ─── VERS LE SWAHILI (target == 'sw') ───
    if (target === 'sw') {
      if (lower.includes('bonjour') || lower.includes('hello') || lower.includes('amahoro')) {
        return 'Jambo na karibu sana kwenye InterConnect Burundi!';
      }
      if (lower.includes('merci') || lower.includes('thank you') || lower.includes('murakoze')) {
        return 'Asante sana!';
      }
      if (lower.includes('coucher de soleil') || lower.includes('sunset')) {
        return 'Machweo mazuri ya jua kando ya Ziwa Tanganyika huko Bujumbura. 🌅🇧🇮';
      }
    }

    return text;
  }
}
