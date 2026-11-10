import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ToggleReactionDto } from './dto/reaction.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Comments')
@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('post/:postId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ajouter un commentaire à une publication' })
  async create(
    @Param('postId', ParseUUIDPipe) postId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.commentsService.create(postId, userId, dto);
  }

  @Get('post/:postId')
  @ApiOperation({ summary: 'Lister les commentaires d’une publication' })
  async findByPost(@Param('postId', ParseUUIDPipe) postId: string) {
    return this.commentsService.findByPost(postId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('reaction')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Réagir ou modifier une réaction sur un post ou commentaire' })
  async toggleReaction(
    @CurrentUser('id') userId: string,
    @Body() dto: ToggleReactionDto,
  ) {
    return this.commentsService.toggleReaction(userId, dto);
  }
}

