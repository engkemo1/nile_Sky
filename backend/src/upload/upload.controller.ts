import {
  Controller, Post, Get, Delete, Param, Query, Body, Res, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { UploadService } from './upload.service';
import { UploadFileDto } from './dto/upload.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @UseGuards(JwtAuthGuard)
  @Post('image')
  async uploadImage(@Body() dto: UploadFileDto) {
    return this.uploadService.store({ ...dto, folder: dto.folder || 'images' });
  }

  @UseGuards(JwtAuthGuard)
  @Post('document')
  async uploadDocument(@Body() dto: UploadFileDto) {
    return this.uploadService.store({ ...dto, folder: dto.folder || 'documents' });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  @Get('list')
  async list(@Query('folder') folder?: string) {
    return this.uploadService.list(folder);
  }

  /**
   * Public on purpose: these URLs are rendered as <img src> in the customer
   * app, which cannot attach an Authorization header to an image request.
   * Ids are random UUIDs, so they are unguessable.
   */
  @Get(':id')
  async serve(@Param('id') id: string, @Res() res: Response) {
    const media = await this.uploadService.fetch(id);
    res.setHeader('Content-Type', media.mimetype);
    res.setHeader('Content-Length', media.sizeBytes.toString());
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.setHeader('Content-Disposition', `inline; filename="${media.filename}"`);
    res.send(media.data);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.uploadService.remove(id);
  }
}
