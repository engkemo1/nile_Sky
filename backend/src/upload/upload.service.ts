import { Injectable, BadRequestException } from '@nestjs/common';

@Injectable()
export class UploadService {
  async handleFileUpload(file: {
    originalname: string;
    mimetype: string;
    size: number;
    buffer?: Buffer;
  }, folder: string = 'general') {
    if (!file) {
      throw new BadRequestException('No file provided for upload');
    }

    // Generate unique file path
    const extension = file.originalname.split('.').pop() || 'jpg';
    const filename = `${folder}_${Date.now()}_${Math.random().toString(36).substring(2, 9)}.${extension}`;
    
    // In production, upload to AWS S3 or Google Cloud Storage.
    // For local/cloud dev, return formatted media CDN URL
    const cdnUrl = `https://images.nilesky.com/uploads/${folder}/${filename}`;

    return {
      success: true,
      filename,
      originalName: file.originalname,
      mimetype: file.mimetype,
      sizeBytes: file.size,
      url: cdnUrl,
    };
  }
}
