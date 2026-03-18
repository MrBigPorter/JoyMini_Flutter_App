import { Injectable } from '@nestjs/common';
import { PrismaService } from '@api/common/prisma/prisma.service';
import { AdQueryDto } from '@api/client/ads/dto/ad-query.dto';

@Injectable()
export class AdsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: AdQueryDto) {
    const now = new Date();

    const where: any = {
      ...(query.status != null ? { status: query.status } : { status: 1 }),
      ...(query.adPosition != null
        ? { adPosition: query.adPosition }
        : { adPosition: 1 }),
      AND: [{ OR: [{ startTime: { lte: now } }, { startTime: null }] }],
    };

    const rows = await this.prisma.advertisement.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
      take: query.limit ?? 10,
      select: {
        id: true,
        title: true,
        adPosition: true,
        sortOrder: true,
        status: true,
        fileType: true, // 1=图片 2=视频
        videoUrl: true,
        jumpCate: true,
        jumpUrl: true,
        relatedId: true,
        startTime: true,
        endTime: true,
        viewCount: true,
        clickCount: true,
        sortType: true,
        imgStyleType: true,
        bannerArray: true,
        img: true,
      },
    });
    return rows.map((r) => ({
      ...r,
      relatedTitleId: r.relatedId,
    }));
  }
}
