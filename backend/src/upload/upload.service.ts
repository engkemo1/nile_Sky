import { Injectable, BadRequestException, NotFoundException, PayloadTooLargeException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Media } from './entities/media.entity';

/** Vercel caps a request body at ~4.5 MB, and base64 inflates by about a third. */
const MAX_BYTES = 3 * 1024 * 1024;

const ALLOWED = new Set([
  'image/jpeg', 'image/png', 'image/webp', 'image/gif',
  'video/mp4', 'video/webm', 'application/pdf',
]);

@Injectable()
export class UploadService {
  constructor(
    @InjectRepository(Media)
    private readonly mediaRepo: Repository<Media>,
  ) {}

  /**
   * Stores a base64 payload and returns the URL the file is served from.
   * Base64 over JSON rather than multipart: it behaves identically on Flutter
   * web and mobile and needs no extra parser in the function.
   */
  async store(dto: {
    filename: string;
    mimetype: string;
    base64: string;
    folder?: string;
  }): Promise<{ id: string; url: string; filename: string; mimetype: string; sizeBytes: number }> {
    if (!dto?.base64) {
      throw new BadRequestException('No file data provided');
    }
    if (!ALLOWED.has(dto.mimetype)) {
      throw new BadRequestException(
        `Unsupported file type "${dto.mimetype}". Allowed: ${[...ALLOWED].join(', ')}`,
      );
    }

    // Accept a bare base64 string or a full data: URL.
    const payload = dto.base64.includes(',')
      ? dto.base64.slice(dto.base64.indexOf(',') + 1)
      : dto.base64;

    let buffer: Buffer;
    try {
      buffer = Buffer.from(payload, 'base64');
    } catch {
      throw new BadRequestException('File data is not valid base64');
    }
    if (buffer.length === 0) {
      throw new BadRequestException('File is empty');
    }
    if (buffer.length > MAX_BYTES) {
      throw new PayloadTooLargeException(
        `File is ${(buffer.length / 1024 / 1024).toFixed(1)} MB; the limit is 3 MB`,
      );
    }

    const saved = await this.mediaRepo.save(
      this.mediaRepo.create({
        filename: (dto.filename || 'upload').slice(0, 255),
        mimetype: dto.mimetype,
        sizeBytes: buffer.length,
        folder: (dto.folder || 'general').slice(0, 60),
        data: buffer,
      }),
    );

    return {
      id: saved.id,
      url: `/upload/${saved.id}`,
      filename: saved.filename,
      mimetype: saved.mimetype,
      sizeBytes: saved.sizeBytes,
    };
  }

  /** Fetches the bytes plus content type for serving. */
  async fetch(id: string): Promise<Media> {
    const media = await this.mediaRepo
      .createQueryBuilder('m')
      .addSelect('m.data')
      .where('m.id = :id', { id })
      .getOne();
    if (!media) throw new NotFoundException('File not found');
    return media;
  }

  /** Metadata only — never the bytes. */
  async list(folder?: string): Promise<Media[]> {
    const q = this.mediaRepo.createQueryBuilder('m').orderBy('m.createdAt', 'DESC').take(200);
    if (folder) q.where('m.folder = :folder', { folder });
    return q.getMany();
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    const res = await this.mediaRepo.delete(id);
    if (!res.affected) throw new NotFoundException('File not found');
    return { deleted: true };
  }
}
