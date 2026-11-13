import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  ParseUUIDPipe,
  UseGuards,
  HttpCode,
  HttpStatus,
  DefaultValuePipe,
  ParseIntPipe,
  ClassSerializerInterceptor,
  UseInterceptors,
  Optional,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import { PostsService } from './posts.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('posts')
@UseInterceptors(ClassSerializerInterceptor)
@Controller({ path: 'posts', version: '1' })
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  @ApiOperation({ summary: 'Lister les publications (paginé, avec traduction optionnelle)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'lang', required: false, type: String, description: 'Langue cible pour la traduction (ex: en, fr, rn)' })
  findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('lang') lang?: string,
  ) {
    return this.postsService.findAll(page, Math.min(limit, 100), lang);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtenir un post par ID' })
  @ApiQuery({ name: 'lang', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Post retourné' })
  @ApiResponse({ status: 404, description: 'Post non trouvé' })
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('lang') lang?: string,
  ) {
    return this.postsService.findOne(id, lang);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Créer une nouvelle publication' })
  @ApiResponse({ status: 201, description: 'Publication créée' })
  create(@CurrentUser() user: User, @Body() dto: CreatePostDto) {
    return this.postsService.create(user.id, dto);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @ApiOperation({ summary: 'Mettre à jour une publication' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: User,
    @Body() dto: UpdatePostDto,
  ) {
    return this.postsService.update(id, user.id, user.role, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Supprimer une publication' })
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.postsService.remove(id, user.id, user.role);
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Aimer une publication' })
  like(@Param('id', ParseUUIDPipe) id: string) {
    return this.postsService.likePost(id);
  }

  @Delete(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Retirer son like d\'une publication' })
  unlike(@Param('id', ParseUUIDPipe) id: string) {
    return this.postsService.unlikePost(id);
  }

  @Get('author/:authorId')
  @ApiOperation({ summary: 'Lister les publications d\'un auteur' })
  findByAuthor(
    @Param('authorId', ParseUUIDPipe) authorId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.postsService.findByAuthor(authorId, page, Math.min(limit, 100));
  }
}
