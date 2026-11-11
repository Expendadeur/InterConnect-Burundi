import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { WINSTON_MODULE_NEST_PROVIDER } from 'nest-winston';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // Use Winston logger as the global NestJS logger
  app.useLogger(app.get(WINSTON_MODULE_NEST_PROVIDER));

  const configService = app.get(ConfigService);
  const nodeEnv = configService.get<string>('nodeEnv');
  const port = configService.get<number>('port');
  const corsOrigin = configService.get<string>('cors.origin');

  // Security: Helmet HTTP headers
  app.use(helmet());

  // CORS
  app.enableCors({
    origin: corsOrigin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  // Global prefix + versioning
  app.setGlobalPrefix('api');
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Global filters and interceptors
  app.useGlobalFilters(new HttpExceptionFilter(app.get(WINSTON_MODULE_NEST_PROVIDER)));
  app.useGlobalInterceptors(new LoggingInterceptor(app.get(WINSTON_MODULE_NEST_PROVIDER)));

  // Swagger only in non-production environments
  if (nodeEnv !== 'production') {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('InterConnect Burundi API')
      .setDescription('API REST pour la plateforme InterConnect Burundi')
      .setVersion('1.0')
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', in: 'header' },
        'access-token',
      )
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', in: 'header' },
        'refresh-token',
      )
      .addTag('auth', 'Authentification & gestion des tokens')
      .addTag('users', 'Gestion des profils utilisateurs')
      .addTag('posts', 'Publications et contenu')
      .addTag('comments', 'Commentaires')
      .addTag('messaging', 'Messagerie temps-réel')
      .addTag('translation', 'Traduction multilingue (IA)')
      .addTag('calls', 'Appels vidéo/audio via LiveKit')
      .addTag('health', 'Health check')
      .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document, {
      swaggerOptions: { persistAuthorization: true },
    });
  }

  const port = process.env.PORT || configService.get<number>('port') || 3000;
  await app.listen(port, '0.0.0.0');
  app.get(WINSTON_MODULE_NEST_PROVIDER).log(
    `🚀 InterConnect Burundi Backend running on port ${port} [${nodeEnv}]`,
    'Bootstrap',
  );
}

bootstrap();
