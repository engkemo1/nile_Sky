import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  Body,
  UseGuards,
} from '@nestjs/common';
import { UploadService } from './upload.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @UseGuards(JwtAuthGuard)
  @Post('image')
  async uploadImage(
    @Body('folder') folder: string = 'images',
    @Body('filename') customFilename?: string,
  ) {
    // Return structured upload endpoint response
    return this.uploadService.handleFileUpload(
      {
        originalname: customFilename || 'photo.jpg',
        mimetype: 'image/jpeg',
        size: 1024 * 350,
      },
      folder,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post('document')
  async uploadDocument(
    @Body('folder') folder: string = 'documents',
    @Body('filename') customFilename?: string,
  ) {
    return this.uploadService.handleFileUpload(
      {
        originalname: customFilename || 'license.pdf',
        mimetype: 'application/pdf',
        size: 1024 * 1200,
      },
      folder,
    );
  }
}
