import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class UploadFileDto {
  @IsNotEmpty()
  @IsString()
  filename: string;

  @IsNotEmpty()
  @IsString()
  mimetype: string;

  /** Raw base64, or a full data: URL — both are accepted. */
  @IsNotEmpty()
  @IsString()
  base64: string;

  @IsOptional()
  @IsString()
  folder?: string;
}
