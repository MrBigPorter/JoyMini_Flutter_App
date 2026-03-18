import { Controller, Get, Query, UseInterceptors } from '@nestjs/common';
import { AdsService } from '@api/client/ads/ads.service';
import { AdQueryDto } from '@api/client/ads/dto/ad-query.dto';
import { CacheTTL } from '@nestjs/cache-manager';
import { PublicCacheInterceptor } from '@api/common/cache/public-cache.interceptor';

@Controller('ads')
@UseInterceptors(PublicCacheInterceptor)
@Controller()
export class AdsController {
  constructor(private readonly svc: AdsService) {}

  @Get()
  @CacheTTL(300_000)
  async list(@Query() query: AdQueryDto) {
    return this.svc.list(query);
  }
}
